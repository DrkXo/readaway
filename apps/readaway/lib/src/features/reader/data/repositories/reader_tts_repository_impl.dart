import 'package:audio_service/audio_service.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/services/tts/tts_chunk_model.dart';
import '../../../../core/services/tts/tts_controller_service.dart';
import '../../../../core/services/tts/tts_models.dart';
import '../../domain/repositories/reader_tts_repository.dart';

@LazySingleton(as: ReaderTtsRepository)
class ReaderTtsRepositoryImpl implements ReaderTtsRepository {
  final TtsControllerService _ttsController;

  ReaderTtsRepositoryImpl(this._ttsController);

  @override
  Stream<TtsPlaybackEvent> get playbackState => _ttsController.playbackState;

  @override
  Stream<TtsChunk> get currentChunk => _ttsController.currentChunk;

  @override
  Stream<List<TtsChunk>> get sentenceQueue =>
      _ttsController.queueVersion.map((_) => _ttsController.queue);

  @override
  Stream<PositionData> get positionDataStream =>
      _ttsController.positionDataStream;

  @override
  Stream<List<double>> get currentWaveform => _ttsController.currentWaveform;

  @override
  Stream<TtsVoiceOption?> get currentVoiceOption =>
      _ttsController.currentVoiceOption;

  @override
  Stream<int> get queueVersion => _ttsController.queueVersion;

  @override
  double get rate => _ttsController.rate;

  @override
  Stream<double> get rateStream => _ttsController.rateStream;

  @override
  List<TtsChunk> get queue => _ttsController.queue;

  @override
  int get queueLength => _ttsController.queueLength;

  @override
  int? get currentChunkIndex => _ttsController.currentChunkIndex;

  @override
  TtsChunk? get activeChunk => _ttsController.activeChunk;

  @override
  TtsVoiceOption? get currentVoice => _ttsController.currentVoice;

  @override
  List<SherpaTtsModelInfo> get availableVoices =>
      _ttsController.availableSherpaModels;

  @override
  MediaItem? get baseTag => _ttsController.baseTag;

  @override
  void setVoice(TtsVoiceOption voice) => _ttsController.setVoice(voice);

  @override
  void start() => _ttsController.start();

  @override
  TaskEither<Failure, Unit> playText(String text, {MediaItem? tag}) {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.playText(text, tag: tag);
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to start TTS playback: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> pause() {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.pause();
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to pause TTS: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> resume() {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.resume();
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to resume TTS: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> stop() {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.stop();
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to stop TTS: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> stopPipeline() {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.stopPipeline();
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to stop TTS pipeline: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> seekToQueueIndex(int index) {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.seekToChunk(index);
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to seek to chunk $index: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> seekToChunk(int index) {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.seekToChunk(index);
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to seek to chunk $index: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> skipToNextSentence() {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.skipToNextSentence();
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to skip to next sentence: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> skipToPreviousSentence() {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.skipToPreviousSentence();
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to skip to previous sentence: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> seekFraction(double fraction) {
    return TaskEither.tryCatch(
      () async {
        final duration = _ttsController.audioPlayer.duration;
        if (duration != null) {
          final target = duration * fraction;
          await _ttsController.seek(target);
        }
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to seek to fraction $fraction: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> seek(Duration position) {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.seek(position);
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to seek audio position: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> seekRelative(Duration offset) {
    return TaskEither.tryCatch(
      () async {
        final current = _ttsController.audioPlayer.position;
        await _ttsController.seek(current + offset);
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to seek by $offset: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> setSpeed(double speed) {
    return setRate(speed);
  }

  @override
  TaskEither<Failure, Unit> setRate(double rate) {
    return TaskEither.tryCatch(
      () async {
        await _ttsController.setRate(rate);
        return unit;
      },
      (error, stack) => TtsSynthesisFailure(
        'Failed to set playback rate: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
