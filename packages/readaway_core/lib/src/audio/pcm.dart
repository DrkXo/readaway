import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Amplitude ceiling below which a sample counts as silence (−46 dBFS).
const double kDefaultSilenceThreshold = 0.005;

/// Seconds of padding retained before the first voiced sample.
const double kHeadPadSeconds = 0.02;

/// Seconds of padding retained after the last voiced sample.
const double kTailPadSeconds = 0.05;

/// Length of the linear fade applied to both buffer edges, in seconds.
const double kEdgeFadeSeconds = 0.003;

/// Half-open interval identifying the voiced region of a PCM buffer.
class SpeechBounds extends Equatable {
  const SpeechBounds(this.startSec, this.endSec);

  final double startSec;
  final double endSec;

  double get durationSec => endSec - startSec;

  @override
  List<Object?> get props => [startSec, endSec];

  @override
  bool? get stringify => true;
}

/// Locates the voiced region of mono floating-point [samples].
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
