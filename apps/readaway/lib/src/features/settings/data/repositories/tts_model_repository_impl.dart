import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/services/http/http_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/path_service.dart';
import '../../../../core/services/tts/sherpa/sherpa_onnx_tts_service.dart';
import '../../../../core/services/tts/tts_model_store.dart';
import '../../../../core/services/tts/tts_models.dart';
import '../../domain/repositories/tts_model_repository.dart';

@LazySingleton(as: TtsModelRepository)
class TtsModelRepositoryImpl implements TtsModelRepository {
  final HttpService _httpService;
  final TtsModelStore _store;
  final SherpaOnnxTtsService _ttsService;
  final AudioPlayerService _audioPlayer;
  final AppPathService _pathService;

  String? _activeModelId;

  TtsModelRepositoryImpl(
    this._httpService,
    this._store,
    this._ttsService,
    this._audioPlayer,
    this._pathService,
  );

  @override
  List<SherpaTtsModelInfo> get availableModels => _store.loadCatalog();

  @override
  Stream<List<SherpaTtsModelInfo>> watchCatalog() => _store.watchCatalog();

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
        final cached = _store.loadCatalog();
        if (!forceRefresh && cached.isNotEmpty) {
          return cached;
        }

        try {
          final response = await _httpService.getCached<Map<String, dynamic>>(
            path: SherpaTtsUrls.manifestApiUrl,
            maxStale: forceRefresh ? Duration.zero : const Duration(days: 1),
            headers: const {'User-Agent': 'readaway'},
          );

          final rawAssets = response.data?['assets'] as List? ?? const [];
          final parsed = <SherpaTtsModelInfo>[];
          for (final a in rawAssets) {
            if (a is! Map<String, dynamic>) continue;
            final name = a['name'] as String?;
            final size = (a['size'] as num?)?.toInt();
            final downloadUrl = a['browser_download_url'] as String?;
            if (name == null || size == null || downloadUrl == null) continue;
            final m = SherpaTtsModelInfo.fromAsset(
              name: name,
              sizeBytes: size,
              downloadUrl: downloadUrl,
              hifiganUrl: SherpaTtsUrls.hifiganUrl,
            );
            if (m != null) parsed.add(m);
          }

          if (parsed.isEmpty && cached.isNotEmpty) {
            return cached;
          }

          parsed.sort((a, b) {
            final c = a.languageLabel.compareTo(b.languageLabel);
            return c != 0 ? c : a.displayName.compareTo(b.displayName);
          });

          if (parsed.isNotEmpty) {
            await _store.saveCatalog(parsed);
            unawaited(_fetchAndSaveChecksums(forceRefresh: forceRefresh));
          }

          return parsed;
        } catch (e, st) {
          logger.e('Failed to fetch TTS manifest from GitHub', e, st);
          if (cached.isNotEmpty) return cached;
          throw Exception('Failed to load TTS catalog: $e');
        }
      },
      onError: (error, stack) => ServerFailure(
        null,
        'Failed to load model catalog: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  Future<void> _fetchAndSaveChecksums({bool forceRefresh = false}) async {
    try {
      final response = await _httpService.getCached<String>(
        path: SherpaTtsUrls.checksumUrl,
        maxStale: forceRefresh ? Duration.zero : const Duration(days: 1),
        headers: const {'User-Agent': 'readaway'},
        responseType: ResponseType.plain,
      );
      final text = response.data;
      if (text == null) return;
      final map = <String, String>{};
      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;
        final hash = parts.first.toLowerCase();
        if (hash.length != 64) continue;
        final name = parts.sublist(1).join(' ');
        map[name] = hash;
      }
      if (map.isNotEmpty) {
        await _store.saveChecksums(map);
      }
    } catch (e) {
      logger.w('Failed to load TTS checksums; skipping verification: $e');
    }
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
