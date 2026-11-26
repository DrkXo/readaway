import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/translation/domain/services/text_chunker.dart';
import 'package:readaway/src/features/translation/domain/services/translation_polisher.dart';

void main() {
  group('TranslationPolisher', () {
    const polisher = TranslationPolisher();

    test('basicPolish removes extra spaces and spaces before punctuation', () {
      expect(
        polisher.basicPolish('  Hello   world  ! How are   you ? '),
        equals('Hello world! How are you?'),
      );
    });

    test('Chinese polish normalizes dashes and cleans punctuation spacing', () {
      expect(
        polisher.polish('这是 一个 测试 -- 是的 。', 'zh'),
        equals('这是 一个 测试 ⸺ 是的。'),
      );
    });

    test('Spanish polish ensures spaces after inverted marks', () {
      expect(
        polisher.polish('?Como estás?!Bien!', 'es'),
        equals('? Como estás?! Bien!'),
      );
    });

    test('French polish ensures appropriate spacing before punctuation', () {
      expect(
        polisher.polish('Bonjour! Comment ça va?', 'fr'),
        equals('Bonjour ! Comment ça va ?'),
      );
    });
  });

  group('TextChunker', () {
    const chunker = TextChunker();

    test('returns single chunk if within maxLength', () {
      final chunks = chunker.splitIntoChunks('Short text.', 100);
      expect(chunks, equals(['Short text.']));
    });

    test('splits on sentence boundary when exceeding maxLength', () {
      final text = 'First sentence. Second sentence. Third sentence.';
      final chunks = chunker.splitIntoChunks(text, 25);
      expect(chunks.length, greaterThan(1));
      expect(chunks.join(''), equals(text));
    });
  });
}
