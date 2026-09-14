import 'dart:math' as math;

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('scaleGapForRate', () {
    test('rate ≤ 0 returns base unchanged (identity)', () {
      final base = 0.175;
      expect(scaleGapForRate(base, 0), same(base));
      expect(scaleGapForRate(base, -1.5), same(base));
      expect(scaleGapForRate(base, double.nan), same(base));
    });

    test('result is quantised to centiseconds', () {
      final bases = List.generate(6, (i) => (i + 1) / 7.0);
      final rates = List.generate(9, (i) => math.pow(2, i - 3).toDouble());
      for (final base in bases) {
        for (final rate in rates) {
          if (!(rate > 0)) continue;
          final r = scaleGapForRate(base, rate);
          final cs = r * 100;
          expect(
            cs,
            closeTo(cs.roundToDouble(), 1e-9),
            reason: 'base=$base rate=$rate',
          );
        }
      }
    });

    test('monotonically non-increasing as rate grows', () {
      final base = 0.168;
      final rates = List.generate(12, (i) => math.pow(2, i - 4).toDouble());
      double? prev;
      for (final rate in rates) {
        final r = scaleGapForRate(base, rate);
        if (prev != null) {
          expect(
            r,
            lessThanOrEqualTo(prev),
            reason: 'rate=$rate should not increase gap',
          );
        }
        prev = r;
      }
    });

    test('rate = 1.0 yields approximately the base (modulo quantisation)', () {
      final base = 0.198;
      final r = scaleGapForRate(base, 1.0);
      // Quantisation error ≤ 0.005 (half-centisecond)
      expect(r, closeTo(base, 0.006));
    });
  });

  group('bakedGapForRate', () {
    test('rate ≤ 0 returns base unchanged (identity)', () {
      final base = 0.175;
      expect(bakedGapForRate(base, 0), same(base));
      expect(bakedGapForRate(base, -1.5), same(base));
      expect(bakedGapForRate(base, double.nan), same(base));
    });

    test('rate = 1.0 yields approximately the base (modulo quantisation)', () {
      final base = 0.198;
      final r = bakedGapForRate(base, 1.0);
      expect(r, closeTo(base, 0.006));
    });

    test(
      'compensates for player speed so wall-clock pause matches scaleGap',
      () {
        // Baked silence S plays in S/rate wall-clock seconds. So
        // bakedGapForRate(base, rate) / rate ≈ scaleGapForRate(base, rate).
        final base = 0.3;
        final rates = [1.0, 1.25, 1.5, 2.0, 3.0];
        for (final rate in rates) {
          final baked = bakedGapForRate(base, rate);
          final wallClock = baked / rate;
          expect(
            wallClock,
            closeTo(scaleGapForRate(base, rate), 0.006),
            reason: 'rate=$rate',
          );
        }
      },
    );

    test('monotonically non-decreasing as rate grows', () {
      final base = 0.168;
      final rates = List.generate(12, (i) => math.pow(2, i - 4).toDouble());
      double? prev;
      for (final rate in rates) {
        if (!(rate > 0)) continue;
        final r = bakedGapForRate(base, rate);
        if (prev != null) {
          expect(
            r,
            greaterThanOrEqualTo(prev),
            reason: 'rate=$rate should not shrink baked gap',
          );
        }
        prev = r;
      }
    });
  });

  group('isCjkLanguage', () {
    test('truthy cases', () {
      expect(isCjkLanguage('zh'), isTrue);
      expect(isCjkLanguage('ZH-Hans'), isTrue);
      expect(isCjkLanguage('zh-Hant-TW'), isTrue);
      expect(isCjkLanguage('cmn'), isFalse); // cmn is not zh
      expect(isCjkLanguage('ja'), isTrue);
      expect(isCjkLanguage('ja-JP'), isTrue);
      expect(isCjkLanguage('ko'), isTrue);
      expect(isCjkLanguage('KO-KR'), isTrue);
    });

    test('falsy cases', () {
      expect(isCjkLanguage('en'), isFalse);
      expect(isCjkLanguage('fr'), isFalse);
      expect(isCjkLanguage('de'), isFalse);
      expect(isCjkLanguage(''), isFalse);
    });
  });

  group('estimateUtteranceSeconds', () {
    test('empty text returns 0', () {
      expect(estimateUtteranceSeconds(text: '', language: 'en'), 0);
    });

    test('punctuation-only text returns 0', () {
      expect(estimateUtteranceSeconds(text: '!!!...???', language: 'en'), 0);
    });

    test('single char hits the floor', () {
      final e = estimateUtteranceSeconds(text: 'a', language: 'en');
      expect(e, kMinUtteranceSeconds);
    });

    test('Latin 30 contiguous chars at 15 cps', () {
      // Exactly 30 lowercase letters: a..z (26) + a..d (4)
      const text = 'abcdefghijklmnopqrstuvwxzyabcd';
      expect(text.length, 30); // sanity check
      final e = estimateUtteranceSeconds(text: text, language: 'en');
      expect(e, closeTo(2.0, 1e-9));
    });

    test('CJK 9 chars at 4.5 cps', () {
      final text = '你好世界一二三四五';
      // 9 chars / 4.5 = 2.0
      final e = estimateUtteranceSeconds(text: text, language: 'zh');
      expect(e, closeTo(2.0, 1e-9));
    });

    test('calibrated CPS overrides default', () {
      const text = 'abcdefghijklmnopqrstuvwxzyabcd'; // 30 chars
      final e = estimateUtteranceSeconds(
        text: text,
        language: 'en',
        calibratedCharsPerSecond: 10,
      );
      expect(e, closeTo(3.0, 1e-9));
    });

    test('punctuation-only simplified (with spaces) preserves parity', () {
      // TS normalization: 'Hi, there!' → 'hi there' → length 8
      final e = estimateUtteranceSeconds(text: 'Hi, there!', language: 'en');
      // 8 chars / 15 cps ≈ 0.533
      expect(e, closeTo(8 / 15, 1e-9));
    });

    test('doubling text approximately doubles duration', () {
      // Use separator-free strings so normalisation preserves exact 2×
      final short = 'abcdefghij'; // 10 chars
      final long = 'abcdefghijabcdefghij'; // 20 chars
      final eShort = estimateUtteranceSeconds(text: short, language: 'en');
      final eLong = estimateUtteranceSeconds(text: long, language: 'en');
      expect(eLong / eShort, closeTo(2.0, 1e-9));
    });
  });

  group('normalizeForCounting', () {
    test('lowercases and strips punctuation', () {
      expect(normalizeForCounting('Hello, World!'), 'hello world');
    });

    test('collapses multiple separators', () {
      expect(normalizeForCounting('foo...bar---baz'), 'foo bar baz');
    });

    test('trims edges', () {
      expect(normalizeForCounting('  hi  '), 'hi');
    });

    test('CJK passes through', () {
      expect(normalizeForCounting('你好世界'), '你好世界');
    });
  });
}
