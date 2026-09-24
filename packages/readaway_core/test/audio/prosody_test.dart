import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('Punctuation Base Pause Grading', () {
    test('standard punctuation grading', () {
      expect(punctuationBasePauseSec('Hello,'), equals(0.18));
      expect(punctuationBasePauseSec('Wait;'), equals(0.22));
      expect(punctuationBasePauseSec('Chapter 1:'), equals(0.22));
      expect(punctuationBasePauseSec('Stop!'), equals(0.28));
      expect(punctuationBasePauseSec('Why?'), equals(0.28));
      expect(punctuationBasePauseSec('This is a sentence.'), equals(0.35));
      expect(punctuationBasePauseSec('Wait for it...'), equals(0.50));
    });

    test('Unicode and international punctuation grading', () {
      // CJK punctuation
      expect(punctuationBasePauseSec('你好，'), equals(0.18));
      expect(punctuationBasePauseSec('苹果、'), equals(0.18));
      expect(punctuationBasePauseSec('测试；'), equals(0.22));
      expect(punctuationBasePauseSec('你好：'), equals(0.22));
      expect(punctuationBasePauseSec('真的吗？'), equals(0.28));
      expect(punctuationBasePauseSec('太棒了！'), equals(0.28));
      expect(punctuationBasePauseSec('结束了。'), equals(0.35));
      expect(punctuationBasePauseSec('未完待续……'), equals(0.50));
      expect(punctuationBasePauseSec('继续…'), equals(0.50));

      // Indic Danda
      expect(punctuationBasePauseSec('नमस्ते ।'), equals(0.35));
      expect(punctuationBasePauseSec('श्रीमद्भगवद्गीता ॥'), equals(0.35));

      // Dashes
      expect(punctuationBasePauseSec('He knew—'), equals(0.22));
      expect(punctuationBasePauseSec('Perhaps–'), equals(0.22));

      // Trailing quotes / brackets
      expect(punctuationBasePauseSec('“太棒了！”'), equals(0.28));
      expect(punctuationBasePauseSec('他说：“好的。”'), equals(0.35));
      expect(punctuationBasePauseSec('“Wait!”'), equals(0.28));
    });
  });

  group('splitProsodySpans', () {
    test('splits CJK text into sub-phrases with punctuation pauses', () {
      const text = '你好，世界！这是测试。';
      final spans = splitProsodySpans(text, enableJitter: false);

      expect(spans.length, equals(3));
      expect(spans[0].text, equals('你好，'));
      expect(spans[0].pauseAfterSec, equals(0.18)); // comma

      expect(spans[1].text, equals('世界！'));
      expect(spans[1].pauseAfterSec, equals(0.28)); // exclamation

      expect(spans[2].text, equals('这是测试。'));
      expect(spans[2].pauseAfterSec, equals(0.35)); // full stop
    });

    test(
      'splits Latin text into sub-phrases with commas, colons and questions',
      () {
        const text = 'Wait, listen: is that real? Yes!';
        final spans = splitProsodySpans(text, enableJitter: false);

        expect(spans.length, equals(4));
        expect(spans[0].text, equals('Wait,'));
        expect(spans[0].pauseAfterSec, equals(0.18));

        expect(spans[1].text, equals('listen:'));
        expect(spans[1].pauseAfterSec, equals(0.22));

        expect(spans[2].text, equals('is that real?'));
        expect(spans[2].pauseAfterSec, equals(0.28));

        expect(spans[3].text, equals('Yes!'));
        expect(spans[3].pauseAfterSec, equals(0.28));
      },
    );

    test('handles ideographic comma and ellipsis', () {
      const text = '苹果、香蕉、橙子……';
      final spans = splitProsodySpans(text, enableJitter: false);

      expect(spans.length, equals(3));
      expect(spans[0].text, equals('苹果、'));
      expect(spans[0].pauseAfterSec, equals(0.18));

      expect(spans[1].text, equals('香蕉、'));
      expect(spans[1].pauseAfterSec, equals(0.18));

      expect(spans[2].text, equals('橙子……'));
      expect(spans[2].pauseAfterSec, equals(0.50));
    });

    test('does not break on decimal numbers', () {
      const text = 'Value is 3.14, okay?';
      final spans = splitProsodySpans(text, enableJitter: false);

      expect(spans.length, equals(2));
      expect(spans[0].text, equals('Value is 3.14,'));
      expect(spans[0].pauseAfterSec, equals(0.18));

      expect(spans[1].text, equals('okay?'));
      expect(spans[1].pauseAfterSec, equals(0.28));
    });

    test('returns single span with 0.0 pause when text has no punctuation', () {
      const text = 'Just plain words';
      final spans = splitProsodySpans(text, enableJitter: false);

      expect(spans.length, equals(1));
      expect(spans[0].text, equals('Just plain words'));
      expect(spans[0].pauseAfterSec, equals(0.0));
    });

    test('sentenceGapMs proportionally scales all span pauses', () {
      const text = '你好，世界！这是测试。';
      final spans = splitProsodySpans(
        text,
        sentenceGapMs: 700,
        enableJitter: false,
      );

      expect(spans.length, equals(3));
      // 700ms is 2x default 350ms sentence terminal
      expect(
        spans[0].pauseAfterSec,
        closeTo(0.18 * 2.0, 0.001),
      ); // comma: 360ms
      expect(
        spans[1].pauseAfterSec,
        closeTo(0.28 * 2.0, 0.001),
      ); // exclamation: 560ms
      expect(
        spans[2].pauseAfterSec,
        closeTo(0.35 * 2.0, 0.001),
      ); // full stop: 700ms
    });

    test('silence scale multiplier scales all span pauses', () {
      const text = 'Hello, world!';
      final spans1x = splitProsodySpans(
        text,
        silenceScaleMultiplier: 1.0,
        enableJitter: false,
      );
      final spans2x = splitProsodySpans(
        text,
        silenceScaleMultiplier: 2.0,
        enableJitter: false,
      );

      expect(
        spans2x[0].pauseAfterSec,
        closeTo(spans1x[0].pauseAfterSec * 2.0, 0.001),
      );
      expect(
        spans2x[1].pauseAfterSec,
        closeTo(spans1x[1].pauseAfterSec * 2.0, 0.001),
      );
    });
  });

  group('Natural Jitter', () {
    test('applies jitter within ±10% bounds', () {
      const base = 0.35;
      final seededRng = math.Random(42);

      for (var i = 0; i < 50; i++) {
        final jittered = applyNaturalJitter(
          base,
          jitterPercent: 0.10,
          random: seededRng,
        );
        expect(jittered, greaterThanOrEqualTo(base * 0.90));
        expect(jittered, lessThanOrEqualTo(base * 1.10));
      }
    });

    test('handles zero or negative base gracefully', () {
      expect(applyNaturalJitter(0.0), equals(0.0));
      expect(applyNaturalJitter(-0.5), equals(-0.5));
    });
  });

  group('Compute Chunk Gap', () {
    const chunkSentence = TtsChunk(
      id: '0:0:0',
      sectionIndex: 0,
      sentenceIndex: 0,
      text: 'Hello world.',
      spokenText: 'Hello world.',
      startOffset: 0,
      endOffset: 12,
      estimatedDurationMs: 1000,
      isParagraphEnd: false,
      paragraphIndex: 0,
      language: 'en',
    );

    const chunkComma = TtsChunk(
      id: '0:1:13',
      sectionIndex: 0,
      sentenceIndex: 1,
      text: 'However,',
      spokenText: 'However,',
      startOffset: 13,
      endOffset: 21,
      estimatedDurationMs: 500,
      isParagraphEnd: false,
      paragraphIndex: 0,
      language: 'en',
    );

    const chunkParagraphEnd = TtsChunk(
      id: '0:2:22',
      sectionIndex: 0,
      sentenceIndex: 2,
      text: 'End of paragraph.',
      spokenText: 'End of paragraph.',
      startOffset: 22,
      endOffset: 39,
      estimatedDurationMs: 1200,
      isParagraphEnd: true,
      paragraphIndex: 0,
      language: 'en',
    );

    test('final chunk always produces 0.0 trailing gap', () {
      final gap = computeChunkGapSec(
        chunkSentence,
        sentenceGapMs: 500,
        paragraphGapMs: 1000,
        isLastChunk: true,
      );
      expect(gap, equals(0.0));
    });

    test('paragraph end chunk uses paragraph gap settings', () {
      final gap = computeChunkGapSec(
        chunkParagraphEnd,
        sentenceGapMs: 500,
        paragraphGapMs: 1000,
        enableJitter: false,
        rate: 1.0,
      );
      expect(gap, equals(1.0)); // 1000ms = 1.0s
    });

    test('sentence chunk scales by custom sentence gap setting', () {
      final gap = computeChunkGapSec(
        chunkSentence,
        sentenceGapMs: 700, // 2x default 350ms
        paragraphGapMs: 1000,
        enableJitter: false,
        rate: 1.0,
      );
      expect(gap, closeTo(0.70, 0.01));
    });

    test('comma chunk scales proportionally with sentence gap setting', () {
      final gap = computeChunkGapSec(
        chunkComma, // 180ms default
        sentenceGapMs: 700, // 2x default 350ms -> 360ms
        paragraphGapMs: 1000,
        enableJitter: false,
        rate: 1.0,
      );
      expect(gap, closeTo(0.36, 0.01));
    });

    test('silence scale multiplier alters final duration', () {
      final gap1x = computeChunkGapSec(
        chunkSentence,
        sentenceGapMs: 350,
        paragraphGapMs: 1000,
        silenceScaleMultiplier: 1.0,
        enableJitter: false,
        rate: 1.0,
      );
      final gap2x = computeChunkGapSec(
        chunkSentence,
        sentenceGapMs: 350,
        paragraphGapMs: 1000,
        silenceScaleMultiplier: 2.0,
        enableJitter: false,
        rate: 1.0,
      );
      expect(gap2x, closeTo(gap1x * 2.0, 0.01));
    });

    test('rate scaling compresses baked gap without zero collapse', () {
      final gap1x = computeChunkGapSec(
        chunkSentence,
        sentenceGapMs: 500,
        paragraphGapMs: 1000,
        enableJitter: false,
        rate: 1.0,
      );
      final gap2x = computeChunkGapSec(
        chunkSentence,
        sentenceGapMs: 500,
        paragraphGapMs: 1000,
        enableJitter: false,
        rate: 2.0,
      );
      expect(gap2x, greaterThan(0.0));
      expect(gap2x, lessThan(gap1x * 2.0));
    });
  });
}
