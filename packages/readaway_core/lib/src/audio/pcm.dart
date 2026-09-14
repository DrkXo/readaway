import 'dart:typed_data';

/// Amplitude ceiling below which a sample counts as silence (−46 dBFS).
///
/// Synthetic vocoder output decays smoothly towards zero, and decoded audio
/// carries dither/ringing roughly in the 1e-4 … 1e-3 band, so speech onsets are
/// detected by amplitude rather than an exact-zero comparison.
const double kDefaultSilenceThreshold = 0.005;

/// Seconds of padding retained before the first voiced sample.
///
/// Protects plosive attacks and breath consonants that peak slightly after the
/// perceptual onset.
const double kHeadPadSeconds = 0.02;

/// Seconds of padding retained after the last voiced sample.
///
/// Longer than [kHeadPadSeconds] because fricatives and vowel decay taper
/// slowly and truncating them sounds clipped.
const double kTailPadSeconds = 0.05;

/// Length of the linear fade applied to both buffer edges, in seconds.
///
/// Roughly 3 ms sits comfortably below one syllable — inaudible on speech, yet
/// vastly longer than a single sample, so the ramp stays smooth.
const double kEdgeFadeSeconds = 0.003;

/// Half-open interval identifying the voiced region of a PCM buffer.
///
/// Offsets are expressed in wall-clock seconds from the start of the analysed
/// buffer.
class SpeechBounds {
  /// Creates bounds spanning `[startSec, endSec)`.
  const SpeechBounds(this.startSec, this.endSec);

  /// Offset of the first retained sample, in seconds.
  final double startSec;

  /// Offset just past the last retained sample, in seconds.
  final double endSec;

  /// Retained duration, in seconds.
  double get durationSec => endSec - startSec;

  @override
  bool operator ==(Object other) =>
      other is SpeechBounds &&
      other.startSec == startSec &&
      other.endSec == endSec;

  @override
  int get hashCode => Object.hash(startSec, endSec);

  @override
  String toString() =>
      'SpeechBounds(${startSec}s, ${endSec}s, '
      'duration: ${durationSec}s)';
}

/// Locates the voiced region of mono floating-point [samples].
///
/// Scans outward from both ends for the first sample exceeding [threshold],
/// then widens the result by [kHeadPadSeconds]/[kTailPadSeconds], clamping to
/// the buffer extent.
///
/// Degenerate inputs return an empty bound at the origin. Buffers that are
/// entirely silent deliberately return the *full* extent so callers schedule a
/// valid clip instead of a zero-length one.
SpeechBounds findSpeechBounds(
  Float32List samples,
  int sampleRate, {
  double threshold = kDefaultSilenceThreshold,
}) {
  if (samples.isEmpty || sampleRate <= 0) return const SpeechBounds(0, 0);

  final totalSec = samples.length / sampleRate;

  var first = -1;
  for (var i = 0; i < samples.length; i++) {
    if (samples[i].abs() > threshold) {
      first = i;
      break;
    }
  }
  if (first == -1) return SpeechBounds(0, totalSec);

  var last = first;
  for (var i = samples.length - 1; i >= first; i--) {
    if (samples[i].abs() > threshold) {
      last = i;
      break;
    }
  }

  final startSec = (first / sampleRate - kHeadPadSeconds).clamp(0.0, totalSec);
  final endSec = ((last + 1) / sampleRate + kTailPadSeconds).clamp(
    0.0,
    totalSec,
  );
  return SpeechBounds(startSec, endSec);
}

/// Ramps the outer samples of [samples] linearly to zero, in place.
///
/// Vocoder output is cut at an amplitude threshold rather than a zero crossing,
/// so clips begin and end on a non-zero sample. Feeding that step straight into
/// a mixer pops audibly between utterances; a short fade removes the
/// discontinuity without perceptibly altering the speech.
///
/// Callers must own [samples] outright — never pass a view aliasing a buffer
/// that is still needed elsewhere.
void applyEdgeFade(
  Float32List samples,
  int sampleRate, {
  double fadeSec = kEdgeFadeSeconds,
}) {
  final requested = (fadeSec * sampleRate).floor();
  final n = requested < samples.length ~/ 2 ? requested : samples.length ~/ 2;
  if (n <= 0) return;

  final last = samples.length - 1;
  for (var i = 0; i < n; i++) {
    final gain = i / n;
    samples[i] *= gain;
    samples[last - i] *= gain;
  }
}
