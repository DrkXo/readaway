import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/failures.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/services/path_service.dart';
import '../../../../core/services/tts/sherpa/sherpa_onnx_tts_service.dart';
import '../../../../core/services/tts/tts_models.dart';
import '../../domain/repositories/tts_model_repository.dart';

@LazySingleton(as: TtsModelRepository)
class TtsModelRepositoryImpl implements TtsModelRepository {
  final SherpaOnnxTtsService _ttsService;
  final AudioPlayerService _audioPlayer;
  final AppPathService _pathService;

  TtsModelRepositoryImpl(
    this._ttsService,
    this._audioPlayer,
    this._pathService,
  );

  @override
  List<SherpaTtsModelInfo> get availableModels => _ttsService.availableModels;

  @override
  String? get activeModelId => _ttsService.activeModel?.id;

  @override
  TaskEither<Failure, Set<String>> getDownloadedModelIds() {
    return TaskEither.tryCatch(
      () async {
        final downloaded = await _ttsService.getDownloadedModels();
        return downloaded.map((m) => m.id).toSet();
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to fetch downloaded models: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> activateModel(String modelId) {
    return TaskEither.tryCatch(
      () async {
        if (_ttsService.activeModel?.id != modelId) {
          await _ttsService.loadModel(modelId);
        }
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
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
  TaskEither<Failure, Unit> deleteModel(String modelId) {
    return TaskEither.tryCatch(
      () async {
        await _ttsService.deleteModel(modelId);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        modelId,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> playPreview(String modelId) {
    return TaskEither.tryCatch(
      () async {
        final previousActive = activeModelId;
        if (_ttsService.activeModel?.id != modelId) {
          await _ttsService.loadModel(modelId);
        }

        final cacheDir = await _pathService.getTtsAudioCacheDirectory();
        final previewPath = p.join(cacheDir.path, 'preview_$modelId.wav');

        final result = await _ttsService.generateToFile(
          text: 'Hello. This is what this voice sounds like while reading.',
          outputPath: previewPath,
          speakerId: 0,
          speed: 1.0,
        );

        await _audioPlayer.playPreviewFile(result.file.path);

        if (previousActive != null && previousActive != modelId) {
          await _ttsService.loadModel(previousActive);
        }

        return unit;
      },
      (error, stack) => AudioPlaybackFailure(
        'Failed to preview voice: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
