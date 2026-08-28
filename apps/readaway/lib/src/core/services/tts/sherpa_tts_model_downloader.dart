part of '../services.dart';

/// Downloads and extracts sherpa-onnx TTS model archives (and any
/// separately-hosted vocoder files) into a destination directory, reporting
/// progress as a stream.
///
/// Owns the low-level HTTP + archive plumbing so [SherpaOnnxTtsService] can
/// focus on model discovery, loading, and synthesis.
@singleton
class SherpaTtsModelDownloader {
  SherpaTtsModelDownloader({required this._client});

  final HttpService _client;

  final _downloadControllers =
      <String, StreamController<ModelDownloadProgress>>{};

  /// Downloads and extracts [model] into [destDir], reporting progress.
  /// Safe to call again for an already-downloaded model (re-downloads/
  /// overwrites); check `isModelDownloaded` first if you want to skip that.
  ///
  /// Cancel by cancelling your subscription to the returned stream; the
  /// underlying Dio request is cancelled with it.
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

      controller.add(
        ModelDownloadProgress(
          modelId: model.id,
          stage: ModelDownloadStage.done,
          fraction: 1,
        ),
      );
    } catch (e) {
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

    onProgress(ModelDownloadStage.extracting, 0);
    final bytes = await archiveFile.readAsBytes();
    final archive = _decodeArchive(bytes, archivePath);

    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      // Archives typically nest everything under one top folder
      // (e.g. `vits-piper-en_US-amy-low/model.onnx`); strip it so files
      // land directly in destDir regardless of the archive's internal name.
      final relative = _stripTopLevelDir(entry.name);
      if (relative.isEmpty) continue;
      final outPath = p.join(destDir.path, relative);
      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(entry.content as List<int>);
    }

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
  }

  Archive _decodeArchive(Uint8List bytes, String path) {
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

  String _stripTopLevelDir(String entryName) {
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
