import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('formatLrcTimestamp', () {
    test('always emits three fractional digits', () {
      // A two-digit fraction is ambiguous: a consumer assuming centiseconds
      // reads .5 as 50ms instead of 500ms.
      expect(
        formatLrcTimestamp(const Duration(milliseconds: 5)),
        '[00:00.005]',
      );
      expect(
        formatLrcTimestamp(const Duration(milliseconds: 500)),
        '[00:00.500]',
      );
      expect(
        formatLrcTimestamp(const Duration(milliseconds: 50)),
        '[00:00.050]',
      );
    });

    test('pads minutes and seconds', () {
      expect(
        formatLrcTimestamp(
          const Duration(minutes: 1, seconds: 2, milliseconds: 3),
        ),
        '[01:02.003]',
      );
    });

    test('does not wrap minutes at 60', () {
      // LRC consumers read the field as a running total, so a 75-minute mark
      // must not become [15:00.000].
      expect(formatLrcTimestamp(const Duration(minutes: 75)), '[75:00.000]');
      expect(
        formatLrcTimestamp(const Duration(minutes: 61, seconds: 30)),
        '[61:30.000]',
      );
    });
  });

  group('parseLrcTimestamp', () {
    test('round-trips what formatLrcTimestamp emits', () {
      for (final ms in [0, 1, 5, 50, 500, 999, 1000, 61_000, 3_600_000]) {
        final d = Duration(milliseconds: ms);
        expect(
          parseLrcTimestamp(formatLrcTimestamp(d)),
          d,
          reason: 'round-trip at ${ms}ms',
        );
      }
    });

    test('reads a bare fraction as decimal, not as centiseconds', () {
      expect(parseLrcTimestamp('[00:00.5]'), const Duration(milliseconds: 500));
      expect(parseLrcTimestamp('[00:00.05]'), const Duration(milliseconds: 50));
      expect(parseLrcTimestamp('[00:00.005]'), const Duration(milliseconds: 5));
    });

    test('accepts a missing fraction and a colon separator', () {
      expect(parseLrcTimestamp('[00:12]'), const Duration(seconds: 12));
      expect(
        parseLrcTimestamp('[00:12:30]'),
        const Duration(seconds: 12, milliseconds: 300),
      );
    });

    test('returns null for a line that is not timestamped', () {
      expect(parseLrcTimestamp('hello'), isNull);
      expect(parseLrcTimestamp('[ti:title]'), isNull);
    });
  });

  group('sanitizeLrcText', () {
    test('collapses newlines that would split one utterance into two', () {
      expect(sanitizeLrcText('one\ntwo'), 'one two');
      expect(sanitizeLrcText('one\r\ntwo'), 'one two');
      expect(sanitizeLrcText('one\rtwo'), 'one two');
    });

    test('strips a leading timestamp that would double-anchor the line', () {
      // Left in place, a parser reads this as two time anchors and renders
      // the line twice.
      expect(sanitizeLrcText('[00:12] hello'), 'hello');
      expect(sanitizeLrcText('[00:12.500]hello'), 'hello');
    });

    test('keeps a timestamp that is not at the start', () {
      expect(sanitizeLrcText('say [00:12] now'), 'say [00:12] now');
    });

    test('strips BOM and zero-width characters', () {
      expect(sanitizeLrcText('﻿hello'), 'hello');
      expect(sanitizeLrcText('hel‌lo'), 'hello');
      expect(sanitizeLrcText('hel⁠lo'), 'hello');
    });

    test('trims surrounding whitespace', () {
      expect(sanitizeLrcText('   hello   '), 'hello');
    });
  });

  group('buildLrc', () {
    test('emits one timestamped line per chunk', () {
      final timeline = TtsTimeline(const [
        Duration(milliseconds: 400),
        Duration(milliseconds: 600),
        Duration(milliseconds: 1000),
      ]);
      final lrc = buildLrc(
        timeline: timeline,
        texts: const ['first', 'second', 'third'],
      );

      final entries = parseLrc(lrc);
      expect(entries, hasLength(3));
      expect(entries[0].start, Duration.zero);
      expect(entries[1].start, const Duration(milliseconds: 400));
      expect(entries[2].start, const Duration(milliseconds: 1000));
      expect(entries.map((e) => e.text), ['first', 'second', 'third']);
    });

    test('timestamps match the timeline exactly, not approximately', () {
      final timeline = TtsTimeline.fromSeconds(const [0.37, 1.29, 2.113]);
      final lrc = buildLrc(timeline: timeline, texts: const ['a', 'b', 'c']);
      final entries = parseLrc(lrc);

      for (var i = 0; i < entries.length; i++) {
        expect(
          entries[i].start.inMilliseconds,
          timeline.startOf(i).inMilliseconds,
          reason: 'chunk $i must land on the measured boundary',
        );
      }
    });

    test('round-trips a long queue without drift', () {
      // Truncating each timestamp would accumulate a visible offset by the end
      // of a chapter.
      final timeline = TtsTimeline.fromSeconds(
        List.generate(200, (i) => 1.337 + i * 0.011),
      );
      final lrc = buildLrc(
        timeline: timeline,
        texts: List.generate(200, (i) => 'line $i'),
      );
      final entries = parseLrc(lrc);

      expect(entries, hasLength(200));
      for (var i = 0; i < entries.length; i++) {
        expect(
          entries[i].start.inMilliseconds,
          timeline.startOf(i).inMilliseconds,
          reason: 'drift at chunk $i',
        );
      }
    });

    test('writes metadata tags and an offset of zero', () {
      final timeline = TtsTimeline.single(const Duration(milliseconds: 100));
      final lrc = buildLrc(
        timeline: timeline,
        texts: const ['only'],
        title: 'Chapter 1',
        artist: 'Author',
        album: 'Book',
      );

      expect(lrc, contains('[ti:Chapter 1]'));
      expect(lrc, contains('[ar:Author]'));
      expect(lrc, contains('[al:Book]'));
      expect(lrc, contains('[offset:0]'));
      // Tags are metadata and must not be parsed as timed entries.
      expect(parseLrc(lrc), hasLength(1));
    });

    test('omits metadata tags that were not supplied', () {
      final timeline = TtsTimeline.single(const Duration(milliseconds: 100));
      final lrc = buildLrc(timeline: timeline, texts: const ['only']);
      expect(lrc, isNot(contains('[ti:')));
      expect(lrc, isNot(contains('[ar:')));
    });

    test('skips chunks whose text sanitizes away to nothing', () {
      // A whitespace-only chunk has no line to render, but it still consumed
      // time, so the surviving lines keep their measured timestamps.
      final timeline = TtsTimeline(const [
        Duration(milliseconds: 400),
        Duration(milliseconds: 600),
        Duration(milliseconds: 1000),
      ]);
      final lrc = buildLrc(
        timeline: timeline,
        texts: const ['first', '   ', 'third'],
      );
      final entries = parseLrc(lrc);

      expect(entries, hasLength(2));
      expect(entries[0].text, 'first');
      expect(entries[0].start, Duration.zero);
      expect(entries[1].text, 'third');
      expect(entries[1].start, const Duration(milliseconds: 1000));
    });

    test('handles an empty timeline without throwing', () {
      final lrc = buildLrc(timeline: TtsTimeline(const []), texts: const []);
      expect(parseLrc(lrc), isEmpty);
    });

    test(
      'strips an embedded timestamp rather than emitting a phantom line',
      () {
        // LRC has no escape mechanism, so a body starting with a timestamp
        // cannot be represented literally. Leaving it in place would make a
        // parser read the line as two anchors and render it twice at 0.1s and
        // 45s. Dropping the text is the only option that keeps the timeline
        // intact.
        final timeline = TtsTimeline(const [Duration(milliseconds: 100)]);
        final lrc = buildLrc(
          timeline: timeline,
          texts: const ['[00:45] embedded timestamp'],
        );
        final entries = parseLrc(lrc);

        expect(entries, hasLength(1));
        expect(entries.single.start, Duration.zero);
        expect(entries.single.text, 'embedded timestamp');
      },
    );

    test('handles a sentence spanning several source lines', () {
      final timeline = TtsTimeline.single(const Duration(milliseconds: 100));
      final lrc = buildLrc(
        timeline: timeline,
        texts: const ['a sentence\nthat wrapped\nacross lines'],
      );
      final entries = parseLrc(lrc);
      expect(entries, hasLength(1));
      expect(entries.single.text, 'a sentence that wrapped across lines');
    });
  });

  group('parseLrc', () {
    test('sorts entries by start time', () {
      const lrc = '[00:02.000] second\n[00:01.000] first\n[00:03.000] third';
      final entries = parseLrc(lrc);
      expect(entries.map((e) => e.text), ['first', 'second', 'third']);
    });

    test('expands a line carrying several timestamps', () {
      // The chorus convention: one body, several anchors.
      const lrc = '[00:10.000][01:20.000] chorus';
      final entries = parseLrc(lrc);
      expect(entries, hasLength(2));
      expect(entries[0].start, const Duration(seconds: 10));
      expect(entries[1].start, const Duration(minutes: 1, seconds: 20));
      expect(entries.every((e) => e.text == 'chorus'), isTrue);
    });

    test('ignores blank lines and metadata tags', () {
      const lrc = '[ti:x]\n[ar:y]\n[00:01.000] real\n\n';
      final entries = parseLrc(lrc);
      expect(entries, hasLength(1));
      expect(entries.single.text, 'real');
    });
  });
}
