import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('construction', () {
    test('is empty when given no durations', () {
      final timeline = TtsTimeline(const <Duration>[]);
      expect(timeline.isEmpty, isTrue);
      expect(timeline.isNotEmpty, isFalse);
      expect(timeline.length, 0);
      expect(timeline.total, Duration.zero);
    });

    test('builds cumulative starts from durations', () {
      final timeline = TtsTimeline(const [
        Duration(milliseconds: 400),
        Duration(milliseconds: 600),
        Duration(milliseconds: 1000),
      ]);

      expect(timeline.length, 3);
      expect(timeline.startOf(0), Duration.zero);
      expect(timeline.startOf(1), const Duration(milliseconds: 400));
      expect(timeline.startOf(2), const Duration(milliseconds: 1000));
      expect(timeline.total, const Duration(milliseconds: 2000));
    });

    test('skips non-positive durations without breaking ordering', () {
      // A zero-length chunk would otherwise make two boundaries identical and
      // leave the binary search with an ambiguous answer.
      final timeline = TtsTimeline(const [
        Duration(milliseconds: 500),
        Duration.zero,
        Duration(milliseconds: 500),
      ]);

      expect(timeline.length, 3);
      expect(timeline.startOf(1), const Duration(milliseconds: 500));
      expect(timeline.startOf(2), const Duration(milliseconds: 500));
      expect(timeline.total, const Duration(milliseconds: 1000));
      for (var i = 0; i < timeline.length; i++) {
        expect(
          timeline.startOf(i) <= timeline.startOf(i + 1),
          isTrue,
          reason: 'starts must be non-decreasing at $i',
        );
      }
    });

    test('rounds seconds to the nearest microsecond', () {
      final timeline = TtsTimeline.fromSeconds(const [0.5, 1.25]);
      expect(timeline.total, const Duration(milliseconds: 1750));
    });

    test('fromSeconds does not accumulate truncation drift', () {
      // Truncating each chunk to whole milliseconds would lose 1ms per chunk.
      final timeline = TtsTimeline.fromSeconds(List.filled(100, 0.0005));
      expect(timeline.total.inMicroseconds, 50000);
    });

    test('single builds a one-chunk timeline', () {
      final timeline = TtsTimeline.single(const Duration(milliseconds: 250));
      expect(timeline.length, 1);
      expect(timeline.total, const Duration(milliseconds: 250));
    });
  });

  group('indexAt', () {
    final timeline = TtsTimeline(const [
      Duration(milliseconds: 400),
      Duration(milliseconds: 600),
      Duration(milliseconds: 1000),
    ]);

    test('maps positions inside a chunk to that chunk', () {
      expect(timeline.indexAt(Duration.zero), 0);
      expect(timeline.indexAt(const Duration(milliseconds: 1)), 0);
      expect(timeline.indexAt(const Duration(milliseconds: 399)), 0);
      expect(timeline.indexAt(const Duration(milliseconds: 401)), 1);
      expect(timeline.indexAt(const Duration(milliseconds: 999)), 1);
      expect(timeline.indexAt(const Duration(milliseconds: 1001)), 2);
      expect(timeline.indexAt(const Duration(milliseconds: 1999)), 2);
    });

    test('assigns an exact boundary to the chunk that starts there', () {
      // The highlight must advance when the new audio begins, not a
      // millisecond before it.
      expect(timeline.indexAt(const Duration(milliseconds: 400)), 1);
      expect(timeline.indexAt(const Duration(milliseconds: 1000)), 2);
    });

    test('clamps out-of-range positions to the ends', () {
      expect(timeline.indexAt(const Duration(milliseconds: -500)), 0);
      expect(timeline.indexAt(const Duration(milliseconds: 999999)), 2);
    });

    test('agrees with startOf across a dense sweep', () {
      // Round-trip: for every chunk i, a position just inside it must resolve
      // back to i. Catches off-by-one in the binary search.
      for (var i = 0; i < timeline.length; i++) {
        final start = timeline.startOf(i);
        expect(timeline.indexAt(start), i, reason: 'start of chunk $i');
        expect(
          timeline.indexAt(start + const Duration(milliseconds: 1)),
          i,
          reason: 'just inside chunk $i',
        );
      }
    });

    test('handles a single-chunk timeline', () {
      final single = TtsTimeline.single(const Duration(milliseconds: 100));
      expect(single.indexAt(Duration.zero), 0);
      expect(single.indexAt(const Duration(milliseconds: 99)), 0);
      expect(single.indexAt(const Duration(milliseconds: 500)), 0);
    });
  });

  group('offsetIn', () {
    final timeline = TtsTimeline(const [
      Duration(milliseconds: 400),
      Duration(milliseconds: 600),
    ]);

    test('reports the offset within the containing chunk', () {
      expect(
        timeline.offsetIn(const Duration(milliseconds: 100)),
        const Duration(milliseconds: 100),
      );
      expect(
        timeline.offsetIn(const Duration(milliseconds: 500)),
        const Duration(milliseconds: 100),
      );
      expect(timeline.offsetIn(Duration.zero), Duration.zero);
    });

    test('clamps a position past the end to the final chunk length', () {
      final last = timeline.durationOf(timeline.length - 1);
      expect(timeline.offsetIn(const Duration(seconds: 99)), last);
    });

    test('is zero on an empty timeline rather than throwing', () {
      final empty = TtsTimeline(const <Duration>[]);
      expect(empty.offsetIn(const Duration(seconds: 5)), Duration.zero);
    });
  });

  group('durationOf and contains', () {
    final timeline = TtsTimeline(const [
      Duration(milliseconds: 400),
      Duration(milliseconds: 600),
    ]);

    test('durationOf sums to the total', () {
      expect(timeline.durationOf(0) + timeline.durationOf(1), timeline.total);
    });

    test('durationOf is zero outside the range', () {
      expect(timeline.durationOf(-1), Duration.zero);
      expect(timeline.durationOf(99), Duration.zero);
    });

    test('contains is inclusive of start and exclusive of end', () {
      expect(timeline.contains(0, Duration.zero), isTrue);
      expect(timeline.contains(0, const Duration(milliseconds: 400)), isFalse);
      expect(timeline.contains(1, const Duration(milliseconds: 400)), isTrue);
    });
  });

  group('progressAt', () {
    test('reports a fraction of the total', () {
      final timeline = TtsTimeline(const [
        Duration(milliseconds: 500),
        Duration(milliseconds: 500),
      ]);
      expect(timeline.progressAt(Duration.zero), 0);
      expect(timeline.progressAt(const Duration(milliseconds: 250)), 0.25);
      expect(timeline.progressAt(const Duration(milliseconds: 500)), 0.5);
      expect(timeline.progressAt(const Duration(milliseconds: 1000)), 1);
    });

    test('clamps beyond the ends', () {
      final timeline = TtsTimeline(const [Duration(milliseconds: 500)]);
      expect(timeline.progressAt(const Duration(seconds: -1)), 0);
      expect(timeline.progressAt(const Duration(seconds: 10)), 1);
    });

    test('is zero rather than NaN for a zero-length timeline', () {
      final timeline = TtsTimeline(const [Duration.zero]);
      expect(timeline.progressAt(const Duration(milliseconds: 100)), 0);
    });
  });

  group('clamping on startOf', () {
    test('clamps indices outside the range to the ends', () {
      final timeline = TtsTimeline(const [
        Duration(milliseconds: 100),
        Duration(milliseconds: 100),
      ]);
      expect(timeline.startOf(-5), Duration.zero);
      expect(timeline.startOf(99), timeline.total);
    });
  });

  group('timelineFromManifest', () {
    final now = DateTime(2026, 1, 1);

    TtsChapterCacheManifest manifestOf(List<double> durationsByIndex) {
      return TtsChapterCacheManifest(
        chapterIndex: 3,
        textHash: 'h',
        voiceId: 'v',
        createdAt: now,
        lastAccessedAt: now,
      ).let(
        (m) => durationsByIndex.asMap().entries.fold(
          m,
          (acc, e) => acc.withChunk(
            TtsCachedChunk(
              chunkIndex: e.key,
              fileName: 'chunk_${e.key}.wav',
              startOffset: 0,
              endOffset: 10,
              durationSec: e.value,
            ),
          ),
        ),
      );
    }

    test('is null when nothing has been measured', () {
      expect(timelineFromManifest(manifestOf(const []), chunkCount: 5), isNull);
    });

    test('is null for an empty page', () {
      final manifest = manifestOf(const [1.0, 2.0]);
      expect(timelineFromManifest(manifest, chunkCount: 0), isNull);
      expect(timelineFromManifest(manifest, chunkCount: -1), isNull);
    });

    test('sums the measured durations', () {
      final timeline = timelineFromManifest(
        manifestOf(const [0.4, 0.6, 1.0]),
        chunkCount: 3,
      )!;
      expect(timeline.length, 3);
      expect(timeline.startOf(1), const Duration(milliseconds: 400));
      expect(timeline.startOf(2), const Duration(milliseconds: 1000));
      expect(timeline.total, const Duration(milliseconds: 2000));
    });

    test('stops at a hole rather than shifting later boundaries', () {
      // Chunk 1 was skipped by synthesis, so chunk 2's real start time is
      // unknowable. Reporting it anyway would be a guess dressed as a
      // measurement, and the highlight would drift from the voice.
      final timeline = timelineFromManifest(
        manifestOf(const [0.4, 0, 1.0]),
        chunkCount: 3,
      )!;
      expect(timeline.length, 1);
      expect(timeline.total, const Duration(milliseconds: 400));
    });

    test('stops at a hole when a later chunk is the only one missing', () {
      final timeline = timelineFromManifest(
        manifestOf(const [0.4, 0.6, 0, 1.0, 1.0]),
        chunkCount: 5,
      )!;
      expect(timeline.length, 2);
      expect(timeline.total, const Duration(milliseconds: 1000));
    });

    test('ignores a negative recorded duration', () {
      final timeline = timelineFromManifest(
        manifestOf(const [0.4, -1.0, 1.0]),
        chunkCount: 3,
      )!;
      expect(timeline.length, 1);
    });

    test('bounds the scan at the page chunk count', () {
      // A manifest carried over from a longer previous page must not stretch
      // the timeline beyond the chunks this page actually has.
      final timeline = timelineFromManifest(
        manifestOf(const [0.4, 0.6, 1.0, 1.0, 1.0]),
        chunkCount: 2,
      )!;
      expect(timeline.length, 2);
      expect(timeline.total, const Duration(milliseconds: 1000));
    });

    test('grows as chunks are appended', () {
      // The pipeline synthesizes in the background, so this function is called
      // repeatedly against a manifest that only gets longer.
      final manifest = manifestOf(const [0.4, 0.6, 1.0]);
      expect(timelineFromManifest(manifest, chunkCount: 3)!.length, 3);

      final grown = manifest.withChunk(
        TtsCachedChunk(
          chunkIndex: 3,
          fileName: 'chunk_3.wav',
          startOffset: 0,
          endOffset: 10,
          durationSec: 0.25,
        ),
      );
      final after = timelineFromManifest(grown, chunkCount: 4)!;
      expect(after.length, 4);
      expect(after.total, const Duration(milliseconds: 2250));
    });

    test('produces a timeline whose own lookup agrees with the manifest', () {
      final timeline = timelineFromManifest(
        manifestOf(const [0.4, 0.6, 1.0]),
        chunkCount: 3,
      )!;
      for (var i = 0; i < timeline.length; i++) {
        expect(
          timeline.indexAt(timeline.startOf(i)),
          i,
          reason: 'chunk $i must own its own start boundary',
        );
      }
    });
  });
}

extension<T> on T {
  /// Local `let` for folding without a named local variable in every test.
  R let<R>(R Function(T) block) => block(this);
}
