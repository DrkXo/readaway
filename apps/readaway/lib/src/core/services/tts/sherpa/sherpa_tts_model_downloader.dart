import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../background_downloader_service.dart';
import '../../logging_service.dart';
import '../../path_service.dart';
import '../tts_model_store.dart';
import '../tts_models.dart';
import 'sherpa_model_catalog.dart';

@singleton
class SherpaTtsModelDownloaderService {
  SherpaTtsModelDownloaderService({
    required this._backgroundDownloader,
    required this._catalog,
    required this._pathService,
    required this._store,
  });

  final BackGroundDownloaderService _backgroundDownloader;
  final SherpaTtsModelCatalogService _catalog;
  final AppPathService _pathService;
  final TtsModelStore _store;

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

  Future<void> pauseDownload(String modelId) =>
      _backgroundDownloader.pause(ttsModelTaskId(modelId));

  Future<void> resumeDownload(String modelId) =>
      _backgroundDownloader.resume(ttsModelTaskId(modelId));

  Future<void> cancelDownload(String modelId) =>
      _backgroundDownloader.cancel(ttsModelTaskId(modelId));

  Future<void> _runDownload(
    SherpaTtsModelInfo model,
    Directory destDir,
    StreamController<ModelDownloadProgress> controller,
  ) async {
    try {
      if (!await destDir.exists()) await destDir.create(recursive: true);

      await _downloadAndExtractArchive(
        model: model,
        destDir: destDir,
        onProgress: (stage, fraction, {speedBytesPerSec, timeRemaining}) =>
            controller.add(
              ModelDownloadProgress(
                modelId: model.id,
                stage: stage,
                fraction: fraction,
                speedBytesPerSec: speedBytesPerSec,
                timeRemaining: timeRemaining,
              ),
            ),
      );

      await _installAuxiliaryFiles(
        model,
        destDir,
        onVocoderProgress: (fraction) => controller.add(
          ModelDownloadProgress(
            modelId: model.id,
            stage: ModelDownloadStage.downloading,
            fraction: fraction,
          ),
        ),
      );

      // Fully downloaded and extracted — persist the index entry.
      await _store.markDownloaded(model.id);

      controller.add(
        ModelDownloadProgress(
          modelId: model.id,
          stage: ModelDownloadStage.done,
          fraction: 1,
        ),
      );
    } on _DownloadCanceledException {
      // User canceled — the caller already removed the download entry.
      return;
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
    required SherpaTtsModelInfo model,
    required Directory destDir,
    required void Function(
      ModelDownloadStage stage,
      double fraction, {
      double? speedBytesPerSec,
      Duration? timeRemaining,
    })
    onProgress,
  }) async {
    final archiveFileName = model.archiveFileName;
    final transfer = await _backgroundDownloader.download(
      taskId: ttsModelTaskId(model.id),
      url: model.downloadUrl,
      filename: archiveFileName,
      saveDirectory: destDir,
      userInitiated: true,
      largeFile: true,
      onTaskFinished: ttsModelTaskFinished,
    );

    var lastProgress = 0.0;
    final progressSub = transfer.progressUpdates.listen((update) {
      lastProgress = update.progress;
      onProgress(
        ModelDownloadStage.downloading,
        update.progress,
        speedBytesPerSec: update.hasNetworkSpeed
            ? update.networkSpeed * 1024 * 1024
            : null,
        timeRemaining: update.hasTimeRemaining ? update.timeRemaining : null,
      );
    });
    final statusSub = transfer.statusUpdates.listen((update) {
      if (update.status == TaskStatus.paused) {
        onProgress(ModelDownloadStage.paused, lastProgress);
      }
    });

    try {
      final result = await transfer.result;
      if (result.status == TaskStatus.canceled) {
        throw const _DownloadCanceledException();
      }
      if (result.status != TaskStatus.complete) {
        throw SherpaTtsException(
          'Download failed for ${model.id}: '
          '${result.exception?.description ?? result.status.name}',
        );
      }

      final archiveFile = await transfer.file;
      await _verifyChecksum(archiveFile, archiveFileName);

      onProgress(ModelDownloadStage.extracting, 0);
      final bytes = await archiveFile.readAsBytes();
      await compute(_extractModelArchiveWorker, (
        bytes: bytes,
        archivePath: archiveFile.path,
        destPath: destDir.path,
      ));
      onProgress(ModelDownloadStage.extracting, 1);

      await archiveFile.delete();
      final marker = File('${archiveFile.path}.done');
      if (await marker.exists()) await marker.delete();
    } finally {
      await progressSub.cancel();
      await statusSub.cancel();
    }
  }

  Future<void> _downloadRawFile({
    required String url,
    required File destFile,
    required void Function(double fraction) onProgress,
  }) async {
    final transfer = await _backgroundDownloader.download(
      url: url,
      filename: p.basename(destFile.path),
      saveDirectory: destFile.parent,
      userInitiated: true,
    );
    final progressSub = transfer.progressUpdates.listen(
      (update) => onProgress(update.progress),
    );
    try {
      final result = await transfer.result;
      if (result.status == TaskStatus.canceled) {
        throw const _DownloadCanceledException();
      }
      if (result.status != TaskStatus.complete) {
        throw SherpaTtsException(
          'Download failed for ${p.basename(destFile.path)}: '
          '${result.exception?.description ?? result.status.name}',
        );
      }
      await _verifyChecksum(destFile, url.split('/').last);
    } finally {
      await progressSub.cancel();
    }
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

    final transfer = await _backgroundDownloader.download(
      url: _catalog.espeakDataUrl,
      filename: 'espeak-ng-data.tar.bz2',
      saveDirectory: tmpDir,
      userInitiated: true,
    );
    final result = await transfer.result;
    if (result.status == TaskStatus.canceled) {
      throw const _DownloadCanceledException();
    }
    if (result.status != TaskStatus.complete) {
      throw SherpaTtsException(
        'Failed to download espeak-ng-data: '
        '${result.exception?.description ?? result.status.name}',
      );
    }
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

  /// Downloads the optional vocoder and shared espeak-ng-data for [model]
  /// if they are missing. Shared by the normal download flow and by
  /// [reconcileModel].
  Future<void> _installAuxiliaryFiles(
    SherpaTtsModelInfo model,
    Directory destDir, {
    required void Function(double fraction) onVocoderProgress,
  }) async {
    final vocoderUrl = model.vocoderUrl;
    if (vocoderUrl != null) {
      final vocoderFile = File(p.join(destDir.path, model.vocoderFileName!));
      if (!await vocoderFile.exists()) {
        await _downloadRawFile(
          url: vocoderUrl,
          destFile: vocoderFile,
          onProgress: onVocoderProgress,
        );
      }
    }
    if (model.needsEspeakData) {
      await _ensureEspeakData(destDir.parent);
    }
  }

  /// Completes a model download that was interrupted after the archive
  /// transfer finished but before extraction ran (e.g. the app was killed
  /// mid-download). Used by
  /// [SherpaOnnxTtsService.reconcilePendingDownloads].
  Future<void> reconcileModel(
    SherpaTtsModelInfo model,
    Directory destDir,
  ) async {
    final archiveFile = File(p.join(destDir.path, model.archiveFileName));
    if (!await archiveFile.exists()) return;

    await _verifyChecksum(archiveFile, model.archiveFileName);
    final bytes = await archiveFile.readAsBytes();
    await compute(_extractModelArchiveWorker, (
      bytes: bytes,
      archivePath: archiveFile.path,
      destPath: destDir.path,
    ));
    await archiveFile.delete();

    await _installAuxiliaryFiles(model, destDir, onVocoderProgress: (_) {});

    // Reconciliation completed the full pipeline — persist the index entry.
    await _store.markDownloaded(model.id);
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

/// Thrown internally when a transfer is canceled by the user; the caller
/// treats it as a quiet stop rather than a failure.
class _DownloadCanceledException implements Exception {
  const _DownloadCanceledException();
}

/// Called by background_downloader when the archive transfer reaches a final
/// state — including if the app was killed and relaunched mid-download.
/// Writes a `.done` marker next to the archive so
/// [SherpaOnnxTtsService.reconcilePendingDownloads] can finish the
/// checksum/extract/vocoder/espeak pipeline on next launch.
@pragma('vm:entry-point')
Future<void> ttsModelTaskFinished(TaskStatusUpdate update) async {
  await _writeDoneMarker(update.task);
}

Future<void> _writeDoneMarker(Task task) async {
  try {
    final path = await task.filePath();
    final file = File(path);
    if (await file.exists()) {
      await File('$path.done').writeAsString('${task.taskId}\n');
    }
  } catch (_) {
    // Best-effort marker; reconciliation also tolerates a missing marker.
  }
}
