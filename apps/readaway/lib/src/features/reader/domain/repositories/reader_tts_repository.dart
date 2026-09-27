import 'package:audio_service/audio_service.dart';
import 'package:readaway_core/readaway_core.dart' show TtsChunk;

import '../../../../core/result/result.dart';
import '../../../../core/services/audio/audio_player_service.dart';
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
  Future<Result<void>> prepareForPlayback();

  /// Index of the document page currently being read aloud by TTS, if any.
  int? get currentPageIndex;

  /// Stream emitting the index of the document page currently being read aloud.
  Stream<int?> get currentPageIndexStream;

  /// Releases worker isolates and unloads models when leaving the reader.
  Future<Result<void>> releaseResources();

  /// Enqueues and begins speaking [text] with optional notification [tag] and [pageIndex].
  Future<Result<void>> playText(
    String text, {
    String? bookPath,
    int? sectionIndex,
    MediaItem? tag,
    int? pageIndex,
    double? startProgression,
    void Function()? onComplete,
  });

  /// Pauses playback.
  Future<Result<void>> pause();

  /// Resumes playback.
  Future<Result<void>> resume();

  /// Stops playback immediately.
  Future<Result<void>> stop();

  /// Stops playback and disposes active playback session resources.
  Future<Result<void>> stopPipeline();

  /// Sets the sleep-timer duration (0 = off) and persists it as a preference.
  void setSleepTimer(Duration duration);

  /// Last persisted sleep-timer duration, or null when off.
  Duration? get sleepTimer;

  /// Seeks to a chunk in the active sentence queue.
  Future<Result<void>> seekToChunk(int index);

  /// Skips to the next sentence chunk.
  Future<Result<void>> skipToNextSentence();

  /// Skips to the previous sentence chunk.
  Future<Result<void>> skipToPreviousSentence();

  /// Seeks to a proportional point (0.0 .. 1.0) within the current sentence.
  Future<Result<void>> seekFraction(double fraction);

  /// Seeks to an absolute audio duration position.
  Future<Result<void>> seek(Duration position);

  /// Seeks relative to current playback position.
  Future<Result<void>> seekRelative(Duration offset);

  /// Adjusts speech playback speed multiplier.
  Future<Result<void>> setSpeed(double speed);

  /// Sets speech playback rate.
  Future<Result<void>> setRate(double rate);

  /// Sets speech playback pitch.
  Future<Result<void>> setPitch(double pitch);
}
