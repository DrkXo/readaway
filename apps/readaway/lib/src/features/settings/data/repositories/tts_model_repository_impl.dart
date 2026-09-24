import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/services/path_service.dart';
import '../../../../core/services/tts/catalog/tts_catalog_service.dart';
import '../../../../core/services/tts/importer/custom_tts_model_importer_service.dart';
import '../../../../core/services/tts/sherpa/sherpa_onnx_tts_service.dart';
import '../../../../core/services/tts/tts_model_store.dart';
import '../../../../core/services/tts/tts_models.dart';
import '../../domain/repositories/tts_model_repository.dart';

@LazySingleton(as: TtsModelRepository)
class TtsModelRepositoryImpl implements TtsModelRepository {
  // ignore: unused_field
  final _log = AppLogger.instance.scope('TtsModelRepository');

  final TtsCatalogService _catalogService;
  final CustomTtsModelImporterService _importerService;
  final TtsModelStore _store;
  final SherpaOnnxTtsService _ttsService;
  final AudioPlayerService _audioPlayer;
  final AppPathService _pathService;

  String? _activeModelId;

  TtsModelRepositoryImpl(
    this._catalogService,
    this._importerService,
    this._store,
    this._ttsService,
    this._audioPlayer,
    this._pathService,
  );

  @override
  List<SherpaTtsModelInfo> get availableModels {
    final catalog = _store.loadCatalog();
    final customModels = _store
        .loadInstalledModelsList()
        .where((m) => m.isCustom)
        .toList();
    return [...customModels, ...catalog];
  }

  @override
  Stream<List<SherpaTtsModelInfo>> watchCatalog() => _store.watchCatalog();

  @override
  Stream<List<SherpaTtsModelInfo>> watchInstalledModels() =>
      _store.watchInstalledModels();

  @override
  Stream<Set<String>> watchDownloadedModelIds() => _store.watchDownloadedIds();

  @override
  String? get activeModelId => _activeModelId ?? _ttsService.activeModel?.id;

  @override
  Future<Result<List<SherpaTtsModelInfo>>> getCatalog({
    bool forceRefresh = false,
  }) {
    return guard(
      () async {
        if (forceRefresh) {
          await _catalogService.syncFromRemote(force: true);
        } else {
          await _catalogService.ensureInitialCatalog();
        }
        return availableModels;
      },
      onError: (error, stack) => ServerFailure(
        null,
        'Failed to load model catalog: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<TtsCatalogSyncResult>> checkForCatalogUpdates() {
    return guard(
      () async {
        return _catalogService.syncFromRemote(force: true);
      },
      onError: (error, stack) => ServerFailure(
        null,
        'Failed to check for model updates: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<Set<String>>> getDownloadedModelIds() {
    return guard(
      () async => _store.loadDownloadedIds(),
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to fetch downloaded models: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<List<SherpaTtsModelInfo>>> getInstalledModels() {
    return guard(
      () async => _ttsService.getDownloadedModels(),
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to fetch installed models: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<CustomModelInspectionResult>> inspectCustomModel(
    String sourcePath,
  ) {
    return guard(
      () async => _importerService.inspectSource(sourcePath),
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to inspect model: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<SherpaTtsModelInfo>> importCustomModel({
    required CustomModelInspectionResult inspection,
    required String displayName,
    required String languageCode,
    required String languageLabel,
    SherpaTtsModelType? typeOverride,
    int speakerCount = 0,
    int sampleRate = 22050,
  }) {
    return guard(
      () async {
        final model = await _importerService.importModel(
          inspection: inspection,
          displayName: displayName,
          languageCode: languageCode,
          languageLabel: languageLabel,
          typeOverride: typeOverride,
          speakerCount: speakerCount,
          sampleRate: sampleRate,
        );
        return model;
      },
      onError: (error, stack) => StorageWriteFailure(
        displayName,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> activateModel(String modelId) {
    return guard(
      () async {
        _activeModelId = modelId;
        if (_ttsService.hasLoadedModel &&
            _ttsService.activeModel?.id != modelId) {
          await _ttsService.loadModel(modelId);
        }
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to activate voice $modelId: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Stream<ModelDownloadProgress> downloadModel(SherpaTtsModelInfo model) {
    return _ttsService.downloadModel(model);
  }

  @override
  Future<void> pauseDownload(String modelId) =>
      _ttsService.pauseDownload(modelId);

  @override
  Future<void> resumeDownload(String modelId) =>
      _ttsService.resumeDownload(modelId);

  @override
  Future<void> cancelDownload(String modelId) =>
      _ttsService.cancelDownload(modelId);

  @override
  Future<Result<void>> deleteModel(String modelId) {
    return guard(
      () async {
        if (_activeModelId == modelId) {
          _activeModelId = null;
        }
        await _ttsService.deleteModel(modelId);
      },
      onError: (error, stack) => StorageWriteFailure(
        modelId,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> playPreview(String modelId) {
    return guard(
      () async {
        final cacheDir = await _pathService.getTtsAudioCacheDirectory();
        final cachedMp3Path = p.join(cacheDir.path, 'preview_$modelId.mp3');

        // 1. Play cached preview audio if available
        if (await File(cachedMp3Path).exists()) {
          await _audioPlayer.playPreviewFile(cachedMp3Path);
          return;
        }

        // 2. Stream / download remote preview sample
        final model = availableModels.where((m) => m.id == modelId).firstOrNull;
        if (model?.previewAudioUrl != null) {
          try {
            await _audioPlayer.playPreviewUrl(
              model!.previewAudioUrl!,
              cacheFilePath: cachedMp3Path,
            );
            return;
          } catch (e) {
            final isDownloaded = await _ttsService.isModelDownloaded(modelId);
            if (!isDownloaded) rethrow;
          }
        }

        // 3. Fallback for downloaded models when offline
        final isDownloaded = await _ttsService.isModelDownloaded(modelId);
        if (isDownloaded) {
          final previousActive = activeModelId;
          if (_ttsService.activeModel?.id != modelId) {
            await _ttsService.loadModel(modelId);
          }

          final previewWavPath = p.join(cacheDir.path, 'preview_$modelId.wav');
          final result = await _ttsService.generateToFile(
            text: 'Hello. This is what this voice sounds like while reading.',
            outputPath: previewWavPath,
            speakerId: 0,
            speed: 1.0,
          );

          await _audioPlayer.playPreviewFile(result.file.path);

          if (previousActive != null && previousActive != modelId) {
            await _ttsService.loadModel(previousActive);
          }

          return;
        }

        throw Exception('No preview audio available for $modelId');
      },
      onError: (error, stack) => AudioPlaybackFailure(
        'Failed to preview voice: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> stopPreview() {
    return guard(
      () async {
        await _audioPlayer.stopPreview();
      },
      onError: (error, stack) => AudioPlaybackFailure(
        'Failed to stop voice preview: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
