import 'package:freezed_annotation/freezed_annotation.dart';

part 'tts_download_task.freezed.dart';

/// Coarse phase machine for a single TTS voice installation.
///
/// Phases are ordered and each contributes a fixed weight to the overall
/// [TtsDownloadTask.fraction], so the progress bar is monotonic and never
/// restarts when a later sub-file (vocoder, espeak-ng-data) begins
/// downloading.
enum TtsDownloadPhase {
  queued,
  downloadingArchive,
  verifyingArchive,
  extractingArchive,
  downloadingAuxiliary,
  finalizing,
  done,
  paused,
  interrupted,
  failed;

  /// True while the pipeline is actively making progress (not terminal, not
  /// paused, not parked-waiting-for-resume).
  bool get isActive => switch (this) {
    TtsDownloadPhase.queued ||
    TtsDownloadPhase.downloadingArchive ||
    TtsDownloadPhase.verifyingArchive ||
    TtsDownloadPhase.extractingArchive ||
    TtsDownloadPhase.downloadingAuxiliary ||
    TtsDownloadPhase.finalizing => true,
    TtsDownloadPhase.done ||
    TtsDownloadPhase.paused ||
    TtsDownloadPhase.interrupted ||
    TtsDownloadPhase.failed => false,
  };
}

/// One row of the shared download state exposed by the TTS download manager.
///
/// [fraction] is the monotonic, phase-weighted overall progress (0..1): it
/// only ever moves forward, even though the underlying sub-transfers
/// (archive, vocoder, espeak-ng-data) each restart their own 0..1 counter.
///
/// [interrupted] is set when a task was rehydrated after the app was killed
/// mid-transfer and is parked waiting for a manual "resume" from the user.
@freezed
abstract class TtsDownloadTask with _$TtsDownloadTask {
  const factory TtsDownloadTask({
    required String modelId,
    required TtsDownloadPhase phase,
    @Default(0) double fraction,
    double? speedBytesPerSec,
    Duration? timeRemaining,
    String? errorMessage,
    @Default(false) bool interrupted,
  }) = _TtsDownloadTask;
}
