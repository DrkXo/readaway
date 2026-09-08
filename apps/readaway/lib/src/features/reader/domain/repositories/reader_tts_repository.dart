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

  /// Current playback pitch multiplier.
  double get pitch;

  /// Stream of playback pitch changes.
  Stream<double> get pitchStream;

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

  /// List of local models/voices available for TTS speech.
  List<TtsVoiceOption> get availableVoices;

  /// Stream of available local voice options.
  Stream<List<TtsVoiceOption>> get availableVoicesStream;

  /// Refreshes and returns available local voice options.
  Future<List<TtsVoiceOption>> loadAvailableVoices();

  /// Media item tag containing album/title/artist/artUri for notifications.
  MediaItem? get baseTag;

  /// Changes the active TTS voice.
  void setVoice(TtsVoiceOption voice);

  /// Initializes/starts the TTS audio pipeline.
  void start();

  /// Prepares engine and worker isolates for playback on demand.
  TaskEither<Failure, Unit> prepareForPlayback();

  /// Index of the document page currently being read aloud by TTS, if any.
  int? get currentPageIndex;

  /// Stream emitting the index of the document page currently being read aloud.
  Stream<int?> get currentPageIndexStream;

  /// Releases worker isolates and unloads models when leaving the reader.
  TaskEither<Failure, Unit> releaseResources();

  /// Enqueues and begins speaking [text] with optional notification [tag] and [pageIndex].
  TaskEither<Failure, Unit> playText(String text, {MediaItem? tag, int? pageIndex});

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

  /// Sets speech playback pitch.
  TaskEither<Failure, Unit> setPitch(double pitch);
}
