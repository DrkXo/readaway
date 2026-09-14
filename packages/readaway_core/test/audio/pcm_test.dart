import 'dart:math' as math;
import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

/// Independently re-scans [samples] following the same spec, providing a
/// second implementation to check the library against.
SpeechBounds _naiveScan(
  Float32List samples,
  int sampleRate, {
  double threshold = kDefaultSilenceThreshold,
}) {
  if (samples.isEmpty || sampleRate <= 0) return const SpeechBounds(0, 0);
  final total = samples.length / sampleRate;

  var firstIdx = -1;
  for (var i = 0; i < samples.length; i++) {
    if (samples[i].abs() > threshold) {
      firstIdx = i;
      break;
    }
  }
  if (firstIdx == -1) return SpeechBounds(0, total);

  var lastIdx = firstIdx;
  for (var i = samples.length - 1; i >= firstIdx; i--) {
    if (samples[i].abs() > threshold) {
      lastIdx = i;
      break;
    }
  }

  final start = firstIdx / sampleRate - kHeadPadSeconds;
  final end = (lastIdx + 1) / sampleRate + kTailPadSeconds;
  return SpeechBounds(
    start < 0 ? 0 : (start > total ? total : start),
    end < 0 ? 0 : (end > total ? total : end),
  );
}

void main() {
  group('SpeechBounds', () {
    test('durationSec returns the span', () {
      const b = SpeechBounds(0.5, 1.2);
      expect(b.durationSec, closeTo(0.7, 1e-12));
    });

    test('equality and hashCode', () {
      const a = SpeechBounds(0.1, 0.9);
      const b = SpeechBounds(0.1, 0.9);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('SpeechBounds'));
    });

    test('inequality on different bounds', () {
      const a = SpeechBounds(0.1, 0.9);
      const b = SpeechBounds(0.2, 0.9);
      expect(a == b, isFalse);
    });
  });

  group('findSpeechBounds', () {
    test('empty buffer returns origin', () {
      final b = findSpeechBounds(Float32List(0), 44100);
      expect(b, const SpeechBounds(0, 0));
    });

    test('zero sample rate returns origin', () {
      final b = findSpeechBounds(Float32List(100), 0);
      expect(b, const SpeechBounds(0, 0));
    });

    test('negative sample rate returns origin', () {
      final b = findSpeechBounds(Float32List(100), -1);
      expect(b, const SpeechBounds(0, 0));
    });

    test('all-silence buffer returns full extent', () {
      final sr = 1000;
      final len = 2000; // 2.0 seconds
      final b = findSpeechBounds(Float32List(len), sr);
      expect(b.startSec, 0);
      expect(b.endSec, closeTo(2.0, 1e-9));
    });

    test('matches naive reference implementation', () {
      final rng = math.Random(42);
      final sr = 800;
      final len = 1200; // 1.5 seconds
      final samples = Float32List(len);
      // Silence everywhere
      for (var i = 0; i < len; i++) {
        samples[i] = rng.nextDouble() * 0.001; // well below threshold
      }
      // Two speech bursts at positions 320 and 880
      samples[320] = 0.61;
      samples[880] = -0.73;

      final lib = findSpeechBounds(samples, sr);
      final naive = _naiveScan(samples, sr);

      expect(lib.startSec, closeTo(naive.startSec, 1e-12));
      expect(lib.endSec, closeTo(naive.endSec, 1e-12));
    });

    test('custom threshold affects detection', () {
      final samples = Float32List(1000);
      samples[500] = 0.01; // above default, below custom
      final lib = findSpeechBounds(samples, 1000, threshold: 0.03);
      final naive = _naiveScan(samples, 1000, threshold: 0.03);
      expect(lib.startSec, closeTo(naive.startSec, 1e-12));
      expect(lib.endSec, closeTo(naive.endSec, 1e-12));
    });

    test('result is contained within [0, totalDuration]', () {
      final sr = 4800;
      final len = 4800; // 1.0 second
      final samples = Float32List(len);
      samples[100] = 1.0;
      samples[200] = -1.0;
      final b = findSpeechBounds(samples, sr);
      expect(b.startSec, greaterThanOrEqualTo(0));
      expect(b.endSec, lessThanOrEqualTo(1.0));
      expect(b.startSec, lessThanOrEqualTo(b.endSec));
    });
  });

  group('applyEdgeFade', () {
    test('zeros the first and last n samples', () {
      final sr = 1000;
      final fadeSec = 0.003;
      final samples = Float32List(1000);
      samples.setAll(0, List.filled(1000, 1.0));
      applyEdgeFade(samples, sr, fadeSec: fadeSec);

      final n = (fadeSec * sr).floor(); // 3
      expect(n, 3);
      expect(samples[0], 0.0); // gain 0/3
      // Float32 arithmetic has ~1e-8 precision vs Dart double's ~1e-16.
      expect(samples[1], closeTo(1.0 / 3, 1e-6)); // gain 1/3
      expect(samples[2], closeTo(2.0 / 3, 1e-6)); // gain 2/3
      expect(samples[3], 1.0); // beyond fade window

      // Symmetric tail
      expect(samples[999], 0.0);
      expect(samples[998], closeTo(1.0 / 3, 1e-6));
      expect(samples[997], closeTo(2.0 / 3, 1e-6));
      expect(samples[996], 1.0);
    });

    test('midpoint is unaffected for even-length buffers', () {
      final sr = 1000;
      final samples = Float32List(1000);
      samples.setAll(0, List.filled(1000, 1.0));
      applyEdgeFade(samples, sr, fadeSec: 0.01);
      // fade window = 10 samples; midpoint index 500 is well beyond
      expect(samples[500], 1.0);
    });

    test('degenerate tiny buffer does not crash', () {
      final samples = Float32List(1);
      samples[0] = 0.5;
      applyEdgeFade(samples, 1000);
      // n = min(requested, len ~/ 2) = min(3, 0) = 0 -> no-op
      expect(samples[0], 0.5);
    });

    test('negative samples fade by absolute gain', () {
      final sr = 1000;
      final samples = Float32List(1000);
      samples.setAll(0, List.filled(1000, -0.8));
      applyEdgeFade(samples, sr, fadeSec: 0.003);
      expect(samples[0], 0.0);
      expect(samples[1], closeTo(-0.8 / 3, 1e-6));
    });
  });
}
