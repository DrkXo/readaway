import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart' show TtsChunk;

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/services/tts/controller/tts_controller_service.dart';
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
  double get pitch => _ttsController.pitch;

  @override
  Stream<double> get pitchStream => _ttsController.pitchStream;

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
  List<TtsVoiceOption> get availableVoices => _ttsController.availableVoices;

  @override
  Stream<List<TtsVoiceOption>> get availableVoicesStream =>
      _ttsController.availableVoicesStream;

  @override
  Future<List<TtsVoiceOption>> loadAvailableVoices() =>
      _ttsController.getInstalledVoices();

  @override
  int? get currentPageIndex => _ttsController.currentPageIndex;

  @override
  Stream<int?> get currentPageIndexStream =>
      _ttsController.currentPageIndexStream;

  @override
  MediaItem? get baseTag => _ttsController.baseTag;

  @override
  void setVoice(TtsVoiceOption voice) => _ttsController.setVoice(voice);

  @override
  void start() => _ttsController.start();

  @override
  void setSleepTimer(Duration duration) =>
      _ttsController.setSleepTimer(duration);

  @override
  Duration? get sleepTimer {
    final minutes = _ttsController.sleepTimerMinutes;
    if (minutes <= 0) return null;
    return Duration(minutes: minutes);
  }

  @override
  Future<Result<void>> prepareForPlayback() {
    return guard(
      () async {
        await _ttsController.prepareForPlayback();
        if (_ttsController.currentVoice == null &&
            _ttsController.availableVoices.isEmpty) {
          throw const TtsNoVoiceSelectedFailure(
            'No voice model is selected or installed.',
          );
        }
      },
      onError: (error, stack) {
        if (error is Failure) return error;
        return TtsSynthesisFailure(
          'Failed to prepare TTS playback: $error',
          cause: error,
          stackTrace: stack,
        );
      },
    );
  }

  @override
  Future<Result<void>> releaseResources() {
    return guard(
      () async {
        await _ttsController.releaseResources();
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to release TTS resources: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> playText(
    String text, {
    MediaItem? tag,
    int? pageIndex,
    double? startProgression,
    void Function()? onComplete,
  }) {
    return guard(
      () async {
        if (_ttsController.currentVoice == null) {
          throw const TtsNoVoiceSelectedFailure(
            'No voice model is selected or installed.',
          );
        }
        await _ttsController.playText(
          text,
          tag: tag,
          pageIndex: pageIndex,
          startProgression: startProgression,
          onComplete: onComplete,
        );
      },
      onError: (error, stack) {
        if (error is Failure) return error;
        return TtsSynthesisFailure(
          'Failed to start TTS playback: $error',
          cause: error,
          stackTrace: stack,
        );
      },
    );
  }

  @override
  Future<Result<void>> pause() {
    return guard(
      () async {
        await _ttsController.pause();
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to pause TTS: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> resume() {
    return guard(
      () async {
        await _ttsController.resume();
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to resume TTS: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> stop() {
    return guard(
      () async {
        await _ttsController.stop();
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to stop TTS: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> stopPipeline() {
    return guard(
      () async {
        await _ttsController.stopPipeline();
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to stop TTS pipeline: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> seekToChunk(int index) {
    return guard(
      () async {
        await _ttsController.seekToChunk(index);
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to seek to chunk $index: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> skipToNextSentence() {
    return guard(
      () async {
        await _ttsController.skipToNextSentence();
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to skip to next sentence: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> skipToPreviousSentence() {
    return guard(
      () async {
        await _ttsController.skipToPreviousSentence();
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to skip to previous sentence: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> seekFraction(double fraction) {
    return guard(
      () async {
        final duration = _ttsController.audioPlayer.duration;
        if (duration != null) {
          final target = duration * fraction;
          await _ttsController.seek(target);
        }
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to seek to fraction $fraction: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> seek(Duration position) {
    return guard(
      () async {
        await _ttsController.seek(position);
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to seek audio position: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> seekRelative(Duration offset) {
    return guard(
      () async {
        final current = _ttsController.audioPlayer.position;
        await _ttsController.seek(current + offset);
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to seek by $offset: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> setSpeed(double speed) {
    return setRate(speed);
  }

  @override
  Future<Result<void>> setRate(double rate) {
    return guard(
      () async {
        await _ttsController.setRate(rate);
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to set playback rate: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> setPitch(double pitch) {
    return guard(
      () async {
        await _ttsController.setPitch(pitch);
      },
      onError: (error, stack) => TtsSynthesisFailure(
        'Failed to set playback pitch: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
