import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  const sanitizer = TextSanitizer();

  group('TextSanitizer.isSpeakable', () {
    test('rejects empty and whitespace-only input', () {
      expect(sanitizer.isSpeakable(''), isFalse);
      expect(sanitizer.isSpeakable('   \t\n '), isFalse);
    });

    test('rejects ornamental dividers and bullet-only lines', () {
      expect(sanitizer.isSpeakable('* * *'), isFalse);
      expect(sanitizer.isSpeakable('----'), isFalse);
      expect(sanitizer.isSpeakable('====='), isFalse);
      expect(sanitizer.isSpeakable('\u2022\u2022\u2022'), isFalse);
      expect(sanitizer.isSpeakable('\u2014\u2014\u2014'), isFalse);
    });

    test('accepts real textual content across scripts', () {
      expect(sanitizer.isSpeakable('hello'), isTrue);
      expect(sanitizer.isSpeakable('Chapter 12'), isTrue);
      expect(sanitizer.isSpeakable('\u3053\u3093\u306b\u3061\u306f'), isTrue);
      expect(
        sanitizer.isSpeakable('\u041f\u0440\u0438\u0432\u0435\u0442'),
        isTrue,
      );
    });
  });

  group('TextSanitizer.sanitizeForSpeech', () {
    test('returns empty string unchanged', () {
      expect(sanitizer.sanitizeForSpeech(''), '');
    });

    test('removes bracketed footnote and citation markers', () {
      expect(
        sanitizer.sanitizeForSpeech('See the appendix.[1] Done.'),
        'See the appendix. Done.',
      );
      expect(
        sanitizer.sanitizeForSpeech('Factual claim (2) stands.'),
        'Factual claim stands.',
      );
    });

    test('repairs hyphenated line breaks from PDF extractors', () {
      expect(
        sanitizer.sanitizeForSpeech('inter-\nnational trade'),
        'international trade',
      );
    });

    test('strips CJK inline reading annotations (keeps base ideograph)', () {
      expect(
        sanitizer.sanitizeForSpeech(
          '\u6f22\u5b57\uff08\u304b\u3093\u3058\uff09\u3092\u8aad\u3080',
        ),
        '\u6f22\u5b57\u3092\u8aad\u3080',
      );
    });

    test('removes invisible and zero-width characters', () {
      expect(sanitizer.sanitizeForSpeech('soft\u00adhyphen'), 'softhyphen');
      expect(sanitizer.sanitizeForSpeech('zero\u200bwidth'), 'zerowidth');
    });

    test('simplifies excessive repeated punctuation', () {
      expect(sanitizer.sanitizeForSpeech('Really????'), 'Really?');
      expect(sanitizer.sanitizeForSpeech('Wait......'), 'Wait...');
    });

    test('normalises smart quotes and dashes', () {
      expect(
        sanitizer.sanitizeForSpeech('\u201cHi\u201d \u2014 bye'),
        '"Hi" - bye',
      );
    });

    test('collapses whitespace and line breaks into single spaces', () {
      expect(
        sanitizer.sanitizeForSpeech('too\tmany\r\n\nspaces'),
        'too many spaces',
      );
    });
  });

  group('TextSanitizer.inferLanguage', () {
    test('infers Japanese from kana', () {
      expect(
        sanitizer.inferLanguage('\u3053\u308c\u306f\u672c\u3067\u3059\u3002'),
        'ja',
      );
    });

    test('infers Chinese from lone Han ideographs', () {
      expect(
        sanitizer.inferLanguage('\u8fd9\u662f\u4e00\u672c\u4e66\u3002'),
        'zh',
      );
    });

    test('infers Korean from Hangul', () {
      expect(
        sanitizer.inferLanguage('\uc774\uac83\uc740 \ucc45\uc785\ub2c8\ub2e4.'),
        'ko',
      );
    });

    test('infers Russian from Cyrillic', () {
      expect(
        sanitizer.inferLanguage(
          '\u042d\u0442\u043e \u043a\u043d\u0438\u0433\u0430.',
        ),
        'ru',
      );
    });

    test('infers Greek, Arabic, Hebrew and Hindi', () {
      expect(
        sanitizer.inferLanguage(
          '\u0391\u03c5\u03c4\u03cc \u03b5\u03af\u03bd\u03b1\u03b9.',
        ),
        'el',
      );
      expect(
        sanitizer.inferLanguage('\u0647\u0630\u0627 \u0643\u062a\u0627\u0628.'),
        'ar',
      );
      expect(sanitizer.inferLanguage('\u05d6\u05d4 \u05e1\u05e4\u05e8.'), 'he');
      expect(
        sanitizer.inferLanguage(
          '\u092f\u0939 \u0915\u093f\u0924\u093e\u092c \u0939\u0948.',
        ),
        'hi',
      );
    });

    test('defaults to English for Latin script and empty input', () {
      expect(sanitizer.inferLanguage('Just plain English.'), 'en');
      expect(sanitizer.inferLanguage(''), 'en');
    });
  });
}
