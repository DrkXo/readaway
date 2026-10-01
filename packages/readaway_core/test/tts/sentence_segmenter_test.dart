import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('SentenceSegmenter Tests', () {
    test('sanitizes zero-width and invisible characters', () {
      const input = 'Hello\u200B world\uFEFF! \u00AD';
      final sanitized = SentenceSegmenter.sanitizeUnicode(input);
      expect(sanitized, equals('Hello world! '));
    });

    test('abbreviation aware splitting does not split on titles and abbreviations', () {
      const input =
          'Dr. Watson met Mrs. Hudson at 8 a.m. It was a lovely day in the U.S.A.';
      final spans = SentenceSegmenter.segmentSentences(input, 'en');

      expect(spans.length, 2);
      expect(spans[0].text, 'Dr. Watson met Mrs. Hudson at 8 a.m.');
      expect(spans[1].text, 'It was a lovely day in the U.S.A.');
    });

    test('tracks accurate character offsets', () {
      const input = 'First sentence. Second sentence.';
      final spans = SentenceSegmenter.segmentSentences(input, 'en');

      expect(spans.length, 2);
      expect(spans[0].text, 'First sentence.');
      expect(spans[0].charStart, 0);
      expect(spans[0].charEnd, 15);

      expect(spans[1].text, 'Second sentence.');
      expect(spans[1].charStart, 16);
      expect(spans[1].charEnd, 32);
    });

    test('splits CJK sentences properly', () {
      const input = 'こんにちは。世界です！また会いましょう。';
      final spans = SentenceSegmenter.segmentSentences(input, 'ja');

      expect(spans.length, 3);
      expect(spans[0].text, 'こんにちは。');
      expect(spans[1].text, '世界です！');
      expect(spans[2].text, 'また会いましょう。');
    });

    test('TtsChunker preprocesses paragraphs into cohesive chunks', () {
      const text =
          'Fresh blood flowed from the numerous wounds on the body. Just by standing there for a short while, Fang Yuan had already accumulated a large pool of blood beneath his feet.\n\nEnemies surrounded him all around; there was already no way out.';
      final chunks = TtsChunker.preprocessText(
        text: text,
        sectionIndex: 0,
        language: 'en',
        isHtml: false,
      );

      expect(chunks.length, 2);

      // Paragraph 0
      expect(chunks[0].paragraphIndex, 0);
      expect(chunks[0].sentenceIndex, 0);
      expect(chunks[0].text, contains('Fresh blood flowed'));
      expect(chunks[0].text, contains('Fang Yuan had already accumulated'));
      expect(chunks[0].isParagraphEnd, isTrue);

      // Paragraph 1
      expect(chunks[1].paragraphIndex, 1);
      expect(chunks[1].sentenceIndex, 1);
      expect(chunks[1].text, contains('Enemies surrounded him'));
      expect(chunks[1].isParagraphEnd, isTrue);
    });

    test('TtsChunker tracks exact character offsets across multiple newlines and spaces', () {
      const text =
          'First paragraph with multiple lines.\n\n\n   Second paragraph indented.\r\n\nThird paragraph.';
      final chunks = TtsChunker.preprocessText(
        text: text,
        sectionIndex: 0,
        language: 'en',
        isHtml: false,
      );

      expect(chunks.length, 3);

      for (final chunk in chunks) {
        // The slice in the original text at [startOffset..endOffset] must exactly equal chunk.text
        expect(
          text.substring(chunk.startOffset, chunk.endOffset),
          equals(chunk.text),
        );

        // Every word span offset must match the exact word in text
        for (final word in chunk.words) {
          expect(
            text.substring(word.startOffset, word.endOffset),
            equals(word.word),
          );
        }
      }
    });

    test(
      'TtsChunker tracks exact offsets and word spans for oversized paragraphs',
      () {
        final para1 = 'Sentence one is short. ' * 15; // > 300 chars
        final text = '$para1\n\n\nParagraph two.';
        final chunks = TtsChunker.preprocessText(
          text: text,
          sectionIndex: 0,
          language: 'en',
          isHtml: false,
          maxParagraphChunkChars: 150,
        );

        expect(chunks.length, greaterThan(2));

        for (final chunk in chunks) {
          expect(
            text.substring(chunk.startOffset, chunk.endOffset),
            equals(chunk.text),
          );
          for (final word in chunk.words) {
            expect(
              text.substring(word.startOffset, word.endOffset),
              equals(word.word),
            );
          }
        }
      },
    );
  });
}
