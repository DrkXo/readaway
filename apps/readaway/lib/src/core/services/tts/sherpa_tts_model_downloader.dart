part of '../services.dart';

/// Downloads and extracts sherpa-onnx TTS model archives (and any
/// separately-hosted vocoder files) into a destination directory, reporting
/// progress as a stream.
///
/// Owns the low-level HTTP + archive plumbing so [SherpaOnnxTtsService] can
/// focus on model discovery, loading, and synthesis.
@singleton
class SherpaTtsModelDownloader {
  SherpaTtsModelDownloader({
    required this._client,
    required this._catalog,
  });

  final HttpService _client;
  final SherpaTtsModelCatalog _catalog;

  final _downloadControllers =
      <String, StreamController<ModelDownloadProgress>>{};

  /// Serializes the one-time shared espeak-ng-data install so concurrent
  /// model downloads don't race to extract it.
  Future<void>? _espeakInstallFuture;

  /// Downloads and extracts [model] into [destDir], reporting progress.
  /// Safe to call again for an already-downloaded model (re-downloads/
  /// overwrites); check `isModelDownloaded` first if you want to skip that.
  ///
  /// Cancel by cancelling your subscription to the returned stream; the
  /// underlying Dio request is cancelled with it. Note that cancellation
  /// only interrupts the network phase — once bytes are fully downloaded,
  /// decode+write runs to completion (see [_extractModelArchiveWorker]).
  Stream<ModelDownloadProgress> downloadModel(
    SherpaTtsModelInfo model,
    Directory destDir,
  ) {
    final controller = StreamController<ModelDownloadProgress>();
    _downloadControllers[model.id] = controller;
    unawaited(_runDownload(model, destDir, controller));
    return controller.stream;
  }

  Future<void> _runDownload(
    SherpaTtsModelInfo model,
    Directory destDir,
    StreamController<ModelDownloadProgress> controller,
  ) async {
    final cancelToken = CancelToken();
    controller.onCancel = () => cancelToken.cancel('cancelled by caller');

    try {
      if (!await destDir.exists()) await destDir.create(recursive: true);

      await _downloadAndExtractArchive(
        url: model.downloadUrl,
        destDir: destDir,
        cancelToken: cancelToken,
        onProgress: (stage, fraction) => controller.add(
          ModelDownloadProgress(
            modelId: model.id,
            stage: stage,
            fraction: fraction,
          ),
        ),
      );

      // Matcha models need a separately-hosted vocoder file.
      final vocoderUrl = model.vocoderUrl;
      if (vocoderUrl != null) {
        final vocoderFile = File(p.join(destDir.path, model.vocoderFileName!));
        if (!await vocoderFile.exists()) {
          await _downloadRawFile(
            url: vocoderUrl,
            destFile: vocoderFile,
            cancelToken: cancelToken,
            onProgress: (fraction) => controller.add(
              ModelDownloadProgress(
                modelId: model.id,
                stage: ModelDownloadStage.downloading,
                fraction: fraction,
              ),
            ),
          );
        }
      }

      // Piper-family models need the shared espeak-ng phonemization data,
      // installed once into the models root (not per-model).
      if (model.needsEspeakData) {
        await _ensureEspeakData(destDir.parent);
      }

      controller.add(
        ModelDownloadProgress(
          modelId: model.id,
          stage: ModelDownloadStage.done,
          fraction: 1,
        ),
      );
    } catch (e, stackTrace) {
      logger.e('Failed to download ${model.id}', e, stackTrace);
      controller.add(
        ModelDownloadProgress(
          modelId: model.id,
          stage: ModelDownloadStage.failed,
          fraction: 0,
        ),
      );
      controller.addError(
        SherpaTtsException('Failed to fetch ${model.id}: $e'),
      );
    } finally {
      await controller.close();
      _downloadControllers.remove(model.id);
    }
  }

  Future<void> _downloadAndExtractArchive({
    required String url,
    required Directory destDir,
    required CancelToken cancelToken,
    required void Function(ModelDownloadStage stage, double fraction)
    onProgress,
  }) async {
    final tmpDir = await getTemporaryDirectory();
    final archivePath = p.join(tmpDir.path, url.split('/').last);
    final archiveFile = File(archivePath);

    await _client.dio.download(
      url,
      archivePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(ModelDownloadStage.downloading, received / total);
        }
      },
    );

    await _verifyChecksum(archiveFile, url.split('/').last);

    onProgress(ModelDownloadStage.extracting, 0);
    final bytes = await archiveFile.readAsBytes();
    // Decompression + file writes are CPU/IO heavy (tens to hundreds of MB
    // for a large TTS model). Run it on a background isolate via compute():
    // the payload is a plain record of sendable values (Uint8List/String),
    // deliberately NOT the CancelToken/onProgress closure from above, so
    // there's no non-sendable state to trip over. This also means the
    // transient decompression buffers live in a throwaway isolate that gets
    // torn down afterwards, instead of inflating the main isolate's heap.
    await compute(_extractModelArchiveWorker, (
      bytes: bytes,
      archivePath: archivePath,
      destPath: destDir.path,
    ));

    onProgress(ModelDownloadStage.extracting, 1);
    await archiveFile.delete();
  }

  Future<void> _downloadRawFile({
    required String url,
    required File destFile,
    required CancelToken cancelToken,
    required void Function(double fraction) onProgress,
  }) async {
    await _client.dio.download(
      url,
      destFile.path,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    await _verifyChecksum(destFile, url.split('/').last);
  }

  /// Verifies [file]'s sha256 against the catalog's checksum for [fileName].
  /// Skips silently when no checksum is available (checksum fetch failed or
  /// the file isn't listed); throws [SherpaTtsException] on mismatch.
  Future<void> _verifyChecksum(File file, String fileName) async {
    final expected = _catalog.checksumFor(fileName);
    if (expected == null) return;
    final actual = await _sha256Of(file);
    if (actual != expected) {
      throw SherpaTtsException(
        'Checksum mismatch for $fileName (expected $expected, got $actual)',
      );
    }
  }

  Future<String> _sha256Of(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Ensures the shared `espeak-ng-data` directory exists under [modelsRoot],
  /// downloading + extracting it once. Concurrent callers share a single
  /// install future.
  Future<void> _ensureEspeakData(Directory modelsRoot) {
    return _espeakInstallFuture ??= _installEspeakData(
      modelsRoot,
    ).whenComplete(() => _espeakInstallFuture = null);
  }

  Future<void> _installEspeakData(Directory modelsRoot) async {
    final espeakDir = Directory(p.join(modelsRoot.path, 'espeak-ng-data'));
    if (await espeakDir.exists()) return;

    final tmpDir = await getTemporaryDirectory();
    final archivePath = p.join(tmpDir.path, 'espeak-ng-data.tar.bz2');
    final archiveFile = File(archivePath);

    await _client.dio.download(_catalog.espeakDataUrl, archivePath);
    await _verifyChecksum(archiveFile, 'espeak-ng-data.tar.bz2');

    final bytes = await archiveFile.readAsBytes();
    // Same reasoning as the model archive: background isolate, sendable
    // record payload only. Whether the archive's top-level `espeak-ng-data/`
    // folder should be preserved or stripped can only be decided after
    // decoding, so both candidate destinations are passed in and the worker
    // picks — see _extractEspeakArchiveWorker.
    await compute(_extractEspeakArchiveWorker, (
      bytes: bytes,
      archivePath: archivePath,
      modelsRootPath: modelsRoot.path,
      espeakDirPath: espeakDir.path,
    ));

    await archiveFile.delete();
    if (!await espeakDir.exists()) {
      throw SherpaTtsException(
        'espeak-ng-data archive did not produce an espeak-ng-data directory',
      );
    }
  }

  static Archive _decodeArchive(Uint8List bytes, String path) {
    if (path.endsWith('.tar.bz2') || path.endsWith('.tbz2')) {
      final tarBytes = BZip2Decoder().decodeBytes(bytes);
      return TarDecoder().decodeBytes(tarBytes);
    } else if (path.endsWith('.tar.gz') || path.endsWith('.tgz')) {
      final tarBytes = GZipDecoder().decodeBytes(bytes);
      return TarDecoder().decodeBytes(tarBytes);
    } else if (path.endsWith('.zip')) {
      return ZipDecoder().decodeBytes(bytes);
    }
    throw SherpaTtsException('Unsupported archive format: $path');
  }

  static String _stripTopLevelDir(String entryName) {
    final normalized = entryName.replaceAll('\\', '/');
    final firstSlash = normalized.indexOf('/');
    if (firstSlash == -1) return normalized;
    return normalized.substring(firstSlash + 1);
  }

  @disposeMethod
  void dispose() {
    for (final c in _downloadControllers.values) {
      c.close();
    }
    _downloadControllers.clear();
  }
}

/// Decodes + writes a model archive, stripping its top-level directory so
/// files land directly in `destPath` regardless of the archive's internal
/// folder name (e.g. `vits-piper-en_US-amy-low/model.onnx` -> `model.onnx`).
///
/// Top-level function (not a class method) taking a single record argument
/// so it can run via [compute] on a background isolate — decompressing and
/// writing hundreds of MB is real CPU/IO work that doesn't belong on the
/// isolate driving the UI. `SherpaTtsModelDownloader._decodeArchive` and
/// `._stripTopLevelDir` are callable here despite being class-private
/// because Dart privacy is per-library, not per-class, and this is a `part
/// of` the same library.
Future<void> _extractModelArchiveWorker(
  ({Uint8List bytes, String archivePath, String destPath}) args,
) async {
  final archive = SherpaTtsModelDownloader._decodeArchive(
    args.bytes,
    args.archivePath,
  );
  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final relative = SherpaTtsModelDownloader._stripTopLevelDir(entry.name);
    if (relative.isEmpty) continue;
    final outFile = File(p.join(args.destPath, relative));
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(entry.content as List<int>);
  }
}

/// Same idea as [_extractModelArchiveWorker], but for the shared
/// espeak-ng-data archive, which — unlike model archives — sometimes needs
/// its top-level folder preserved rather than stripped. Since that can only
/// be determined after decoding, both candidate destinations are passed in
/// and this function picks the right one internally.
Future<void> _extractEspeakArchiveWorker(
  ({
    Uint8List bytes,
    String archivePath,
    String modelsRootPath,
    String espeakDirPath,
  })
  args,
) async {
  final archive = SherpaTtsModelDownloader._decodeArchive(
    args.bytes,
    args.archivePath,
  );
  final files = archive.files.where((e) => e.isFile).toList();
  final hasTopLevelDir = files.any(
    (e) => e.name.replaceAll('\\', '/').startsWith('espeak-ng-data/'),
  );
  final basePath = hasTopLevelDir ? args.modelsRootPath : args.espeakDirPath;
  for (final entry in files) {
    final outFile = File(p.join(basePath, entry.name));
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(entry.content as List<int>);
  }
}
