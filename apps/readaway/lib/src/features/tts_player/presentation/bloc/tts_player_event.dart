part of 'tts_player_bloc.dart';

@freezed
abstract class TtsPlayerEvent with _$TtsPlayerEvent {
  /// Starts (or restarts) playback from [pageIndex] of the open document.
  const factory TtsPlayerEvent.playFromPage(int pageIndex) = _PlayFromPage;

  /// Toggles play/pause based on the current state.
  const factory TtsPlayerEvent.playPause() = _PlayPause;

  const factory TtsPlayerEvent.pause() = _Pause;

  const factory TtsPlayerEvent.resume() = _Resume;

  /// Pauses playback but keeps the session (mini-player stays visible).
  const factory TtsPlayerEvent.stop() = _Stop;

  /// Fully shuts down the session: stops audio, clears state, hides the
  /// mini-player. The singleton bloc itself stays alive.
  const factory TtsPlayerEvent.closePlayer() = _ClosePlayer;

  const factory TtsPlayerEvent.nextSentence() = _NextSentence;

  const factory TtsPlayerEvent.previousSentence() = _PreviousSentence;

  const factory TtsPlayerEvent.setRate(double rate) = _SetRate;

  /// UI-only for now — sherpa-onnx has no runtime pitch knob.
  const factory TtsPlayerEvent.setPitch(double pitch) = _SetPitch;

  const factory TtsPlayerEvent.setVoice(TtsVoiceOption voice) = _SetVoice;

  /// Sets a sleep timer; null cancels it.
  const factory TtsPlayerEvent.setSleepTimer(Duration? duration) =
      _SetSleepTimer;

  const factory TtsPlayerEvent.cancelSleepTimer() = _CancelSleepTimer;

  // ---------------------------------------------------------------------
  // Internal events
  // ---------------------------------------------------------------------

  /// Restores persisted rate/voice on bloc construction.
  const factory TtsPlayerEvent.restoreSettings() = _RestoreSettings;

  /// Fed by the controller's playback lifecycle stream.
  const factory TtsPlayerEvent.playbackChanged(TtsPlaybackEvent event) =
      _PlaybackChanged;

  /// Fed by the controller's current-chunk stream.
  const factory TtsPlayerEvent.chunkChanged(TtsChunk chunk) = _ChunkChanged;

  /// One-second tick while a sleep timer is running.
  const factory TtsPlayerEvent.sleepTimerTick() = _SleepTimerTick;
}
