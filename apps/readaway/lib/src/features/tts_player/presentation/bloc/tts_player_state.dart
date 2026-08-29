part of 'tts_player_bloc.dart';

@freezed
abstract class TtsPlayerState with _$TtsPlayerState {
  const factory TtsPlayerState({
    @Default(false) bool loading,
    String? error,
    @Default(TtsPlaybackState.idle) TtsPlaybackState playbackState,
    @Default(0) int currentPageIndex,
    @Default(0) int totalPages,
    @Default(-1) int currentChunkIndex,
    @Default(0) int chunkCount,
    @Default(<String>[]) List<String> pageSentences,
    TtsVoiceOption? voice,
    @Default(1.0) double rate,
    @Default(1.0) double pitch,
    Duration? sleepTimerRemaining,
  }) = _TtsPlayerState;

  const TtsPlayerState._();

  /// Whether a playback session is currently active (anything but idle).
  bool get isActive => playbackState != TtsPlaybackState.idle;

  bool get isPlaying => playbackState == TtsPlaybackState.playing;

  bool get isPaused => playbackState == TtsPlaybackState.paused;

  /// The sentence currently being spoken, for the mini-player snippet.
  String? get currentSentenceText {
    if (currentChunkIndex < 0 || currentChunkIndex >= pageSentences.length) {
      return null;
    }
    return pageSentences[currentChunkIndex];
  }
}
