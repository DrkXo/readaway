import 'package:audio_service/audio_service.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/services/tts/tts_chunk_model.dart';
import '../../../../core/services/tts/tts_models.dart';

/// Contract for TTS playback operations and reactive state streams in the Reader feature.
abstract interface class ReaderTtsRepository {
  /// Stream of player state events (idle, loading, playing, paused, completed, etc.).
  Stream<TtsPlaybackEvent> get playbackState;

  /// Stream of currently spoken sentence chunk.
  Stream<TtsChunk> get currentChunk;

  /// Stream of all chunks in the current page sentence queue.
  Stream<List<TtsChunk>> get sentenceQueue;

  /// Stream of intra-chunk audio position data.
  Stream<PositionData> get positionDataStream;

  /// Stream of current waveform amplitude samples.
  Stream<List<double>> get currentWaveform;

  /// Stream of the active voice option.
  Stream<TtsVoiceOption?> get currentVoiceOption;

  /// Emits whenever the sentence queue is updated.
  Stream<int> get queueVersion;

  /// Current playback rate multiplier.
  double get rate;

  /// Stream of playback rate changes.
  Stream<double> get rateStream;

  /// All sentence chunks for the current page.
  List<TtsChunk> get queue;

  /// Number of chunks in the current page queue.
  int get queueLength;

  /// Index of the currently active chunk.
  int? get currentChunkIndex;

  /// Currently active [TtsChunk], if any.
  TtsChunk? get activeChunk;

  /// Currently selected voice option, if any.
  TtsVoiceOption? get currentVoice;

  /// List of local models available for TTS speech.
  List<SherpaTtsModelInfo> get availableVoices;

  /// Media item tag containing album/title/artist/artUri for notifications.
  MediaItem? get baseTag;

  /// Changes the active TTS voice.
  void setVoice(TtsVoiceOption voice);

  /// Initializes/starts the TTS audio pipeline.
  void start();

  /// Enqueues and begins speaking [text] with optional notification [tag].
  TaskEither<Failure, Unit> playText(String text, {MediaItem? tag});

  /// Pauses playback.
  TaskEither<Failure, Unit> pause();

  /// Resumes playback.
  TaskEither<Failure, Unit> resume();

  /// Stops playback immediately.
  TaskEither<Failure, Unit> stop();

  /// Stops playback and disposes active playback session resources.
  TaskEither<Failure, Unit> stopPipeline();

  /// Seeks to a specific sentence in the current page queue.
  TaskEither<Failure, Unit> seekToQueueIndex(int index);

  /// Alias for seeking to a chunk in the active sentence queue.
  TaskEither<Failure, Unit> seekToChunk(int index);

  /// Skips to the next sentence chunk.
  TaskEither<Failure, Unit> skipToNextSentence();

  /// Skips to the previous sentence chunk.
  TaskEither<Failure, Unit> skipToPreviousSentence();

  /// Seeks to a proportional point (0.0 .. 1.0) within the current sentence.
  TaskEither<Failure, Unit> seekFraction(double fraction);

  /// Seeks to an absolute audio duration position.
  TaskEither<Failure, Unit> seek(Duration position);

  /// Seeks relative to current playback position.
  TaskEither<Failure, Unit> seekRelative(Duration offset);

  /// Adjusts speech playback speed multiplier.
  TaskEither<Failure, Unit> setSpeed(double speed);

  /// Sets speech playback rate.
  TaskEither<Failure, Unit> setRate(double rate);
}
