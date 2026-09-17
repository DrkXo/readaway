import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core_rust/readaway_core_rust.dart';

void main() {
  group('TtsChunk model tests', () {
    test('instantiates TtsChunk with valid fields', () {
      const chunk = TtsChunk(
        id: '0:0:0',
        sectionIndex: 0,
        sentenceIndex: 0,
        text: 'Hello world.',
        spokenText: 'Hello world.',
        startOffset: 0,
        endOffset: 12,
        estimatedDurationMs: 800,
      );

      expect(chunk.id, '0:0:0');
      expect(chunk.sectionIndex, 0);
      expect(chunk.sentenceIndex, 0);
      expect(chunk.text, 'Hello world.');
      expect(chunk.spokenText, 'Hello world.');
      expect(chunk.startOffset, 0);
      expect(chunk.endOffset, 12);
      expect(chunk.estimatedDurationMs, 800);
      expect(chunk.toString(), contains('Hello world.'));
    });

    test('maps RustTtsChunk to Dart TtsChunk properly', () {
      final rustChunk = RustTtsChunk(
        id: '1:2:45',
        sectionIndex: 1,
        sentenceIndex: 2,
        displayText: 'I paid \$42.50 for lunch.',
        spokenText: 'I paid forty-two dollars and fifty cents for lunch.',
        startOffset: BigInt.from(45),
        endOffset: BigInt.from(69),
        estimatedDurationMs: 2500,
        isParagraphEnd: true,
        paragraphIndex: 1,
      );

      final dartChunk = TtsChunk.fromRust(rustChunk);

      expect(dartChunk.id, '1:2:45');
      expect(dartChunk.sectionIndex, 1);
      expect(dartChunk.sentenceIndex, 2);
      expect(dartChunk.text, 'I paid \$42.50 for lunch.');
      expect(dartChunk.spokenText, 'I paid forty-two dollars and fifty cents for lunch.');
      expect(dartChunk.startOffset, 45);
      expect(dartChunk.endOffset, 69);
      expect(dartChunk.estimatedDurationMs, 2500);
      expect(dartChunk.isParagraphEnd, isTrue);
      expect(dartChunk.paragraphIndex, 1);
    });

    test('equality and hashcode hold for identical chunks', () {
      const chunk1 = TtsChunk(
        id: '1:1:0',
        sectionIndex: 1,
        sentenceIndex: 1,
        text: 'Test',
        spokenText: 'Test',
        startOffset: 0,
        endOffset: 4,
        estimatedDurationMs: 300,
      );
      const chunk2 = TtsChunk(
        id: '1:1:0',
        sectionIndex: 1,
        sentenceIndex: 1,
        text: 'Test',
        spokenText: 'Test',
        startOffset: 0,
        endOffset: 4,
        estimatedDurationMs: 300,
      );

      expect(chunk1, equals(chunk2));
      expect(chunk1.hashCode, equals(chunk2.hashCode));
    });
  });
}
