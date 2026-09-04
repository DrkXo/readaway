part of '../../services.dart';

@singleton
class SherpaTtsModelDownloaderService {
  SherpaTtsModelDownloaderService({
    required this._client,
    required this._catalog,
    required this._pathService,
  });

  final HttpService _client;
  final SherpaTtsModelCatalogService _catalog;
  final AppPathService _pathService;

  final _downloadControllers =
      <String, StreamController<ModelDownloadProgress>>{};

  Future<void>? _espeakInstallFuture;

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
    final tmpDir = await _pathService.tempDirectory;
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

  Future<void> _ensureEspeakData(Directory modelsRoot) {
    return _espeakInstallFuture ??= _installEspeakData(
      modelsRoot,
    ).whenComplete(() => _espeakInstallFuture = null);
  }

  Future<void> _installEspeakData(Directory modelsRoot) async {
    final espeakDir = Directory(p.join(modelsRoot.path, 'espeak-ng-data'));
    if (await espeakDir.exists()) return;

    final tmpDir = await _pathService.tempDirectory;
    final archivePath = p.join(tmpDir.path, 'espeak-ng-data.tar.bz2');
    final archiveFile = File(archivePath);

    await _client.dio.download(_catalog.espeakDataUrl, archivePath);
    await _verifyChecksum(archiveFile, 'espeak-ng-data.tar.bz2');

    final bytes = await archiveFile.readAsBytes();

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

Future<void> _extractModelArchiveWorker(
  ({Uint8List bytes, String archivePath, String destPath}) args,
) async {
  final archive = SherpaTtsModelDownloaderService._decodeArchive(
    args.bytes,
    args.archivePath,
  );
  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final relative = SherpaTtsModelDownloaderService._stripTopLevelDir(
      entry.name,
    );
    if (relative.isEmpty) continue;
    final outFile = File(p.join(args.destPath, relative));
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(entry.content as List<int>);
  }
}

Future<void> _extractEspeakArchiveWorker(
  ({
    Uint8List bytes,
    String archivePath,
    String modelsRootPath,
    String espeakDirPath,
  })
  args,
) async {
  final archive = SherpaTtsModelDownloaderService._decodeArchive(
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
