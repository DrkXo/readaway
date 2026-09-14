import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

/// Asserts every chunk's offsets faithfully reproduce its display text.
void expectFaithfulOffsets(List<TtsChunk> chunks, String source) {
  for (final chunk in chunks) {
    expect(chunk.startOffset, inInclusiveRange(0, source.length));
    expect(chunk.endOffset, inInclusiveRange(chunk.startOffset, source.length));
    expect(source.substring(chunk.startOffset, chunk.endOffset), chunk.text);
  }
}

/// Asserts chunks are ordered and mutually non-overlapping.
void expectMonotonic(List<TtsChunk> chunks) {
  for (var i = 1; i < chunks.length; i++) {
    expect(
      chunks[i].startOffset,
      greaterThanOrEqualTo(chunks[i - 1].endOffset),
      reason: 'chunk $i overlaps predecessor',
    );
  }
}

void main() {
  const chunker = TextChunker();

  group('TextChunker.chunkSentences', () {
    test('returns empty list for blank input', () {
      expect(chunker.chunkSentences(''), isEmpty);
      expect(chunker.chunkSentences('   \n\t '), isEmpty);
    });

    test('splits paragraphs into sentences with metadata', () {
      const source = 'First sentence. Second one!\n\nThird paragraph here.';
      final chunks = chunker.chunkSentences(source);

      expect(
        chunks.map((c) => c.text),
        orderedEquals([
          'First sentence.',
          'Second one!',
          'Third paragraph here.',
        ]),
      );
      expect(chunks.map((c) => c.paragraphIndex), orderedEquals([0, 0, 1]));
      expect(
        chunks.map((c) => c.isParagraphEnd),
        orderedEquals([false, true, true]),
      );
      expect(chunks.every((c) => c.language == 'en'), isTrue);
      expectFaithfulOffsets(chunks, source);
      expectMonotonic(chunks);
    });

    test('computes word spans relative to the chunk text', () {
      final chunks = chunker.chunkSentences('Alpha beta gamma.');
      final words = chunks.single.words;

      expect(
        words.map((w) => w.word),
        orderedEquals(['Alpha', 'beta', 'gamma.']),
      );
      expect(words.first.startOffset, 0);
      expect(words.last.endOffset, chunks.single.text.length);
    });

    test('protects decimal numbers from premature termination', () {
      final chunks = chunker.chunkSentences('Pi is 3.14 approximately. End.');
      expect(
        chunks.map((c) => c.text),
        orderedEquals(['Pi is 3.14 approximately.', 'End.']),
      );
    });

    test('does not terminate on common abbreviations', () {
      final chunks = chunker.chunkSentences('Dr. Smith arrived. He waited.');
      expect(
        chunks.map((c) => c.text),
        orderedEquals(['Dr. Smith arrived.', 'He waited.']),
      );
    });

    test('does not terminate on dotted acronyms', () {
      final chunks = chunker.chunkSentences('Visit the U.S.A. today. Thanks.');
      expect(
        chunks.map((c) => c.text),
        orderedEquals(['Visit the U.S.A. today.', 'Thanks.']),
      );
    });

    test('retains dialogue attributions attached to quoted exclamations', () {
      final chunks = chunker.chunkSentences(
        '"Wait!" he said quietly. She left.',
      );
      expect(
        chunks.map((c) => c.text),
        orderedEquals(['"Wait!" he said quietly.', 'She left.']),
      );
    });

    test('terminates on ellipses', () {
      final chunks = chunker.chunkSentences('Well... okay. Fine.');
      expect(
        chunks.map((c) => c.text),
        orderedEquals(['Well...', 'okay.', 'Fine.']),
      );
    });

    test('respects maxChunkChars via hierarchical clause wrapping', () {
      final buffer = StringBuffer();
      for (var i = 1; i <= 40; i++) {
        buffer.write('Sentence number $i rambles onward');
        buffer.write(i == 40 ? '.' : ', ');
      }
      final source = buffer.toString();

      final chunks = chunker.chunkSentences(
        source,
        maxChunkChars: 118,
        sanitizeForSpeech: false,
      );

      expect(chunks.length, greaterThan(1));
      expect(chunks.every((c) => c.text.length <= 112), isTrue);
      expect(chunks.every((c) => c.language == 'en'), isTrue);
      expect(chunks.last.isParagraphEnd, isTrue);
      expectFaithfulOffsets(chunks, source);
      expectMonotonic(chunks);
    });

    test('marks paragraph end only on the final chunk of each paragraph', () {
      final chunks = chunker.chunkSentences('One. Two. Three.\n\nFour.');
      expect(
        chunks.map((c) => c.isParagraphEnd),
        orderedEquals([false, false, true, true]),
      );
    });

    test('filters unspeakable ornamental-divider paragraphs', () {
      const source = 'Real text here.\n\n* * *\n\nMore text.';
      final chunks = chunker.chunkSentences(source);

      expect(
        chunks.map((c) => c.text),
        orderedEquals(['Real text here.', 'More text.']),
      );
      // Physical paragraph slots are preserved, so indexes reflect the
      // surviving paragraphs' original positions (0 and 2).
      expect(chunks.map((c) => c.paragraphIndex), orderedEquals([0, 2]));
      expectFaithfulOffsets(chunks, source);
    });

    test('segments CJK sentences and infers Japanese', () {
      const source =
          '\u4eca\u65e5\u306f\u6674\u308c\u3067\u3059\u3002\u660e\u65e5\u306f\u96e8\u3067\u3059\u304b\uff1f\u3044\u3044\u3048\u3002';
      final chunks = chunker.chunkSentences(source);

      expect(chunks, hasLength(3));
      expect(chunks.every((c) => c.language == 'ja'), isTrue);
      expect(chunks.last.isParagraphEnd, isTrue);
      expectFaithfulOffsets(chunks, source);
    });

    test('populates spokenText when sanitisation is enabled', () {
      final chunks = chunker.chunkSentences('Claim.[1] Rest.');
      expect(chunks.first.text, 'Claim.[1] Rest.');
      expect(chunks.first.spokenText, 'Claim. Rest.');
      expect(chunks.first.speechContent, 'Claim. Rest.');
    });

    test('round-trips through JSON for isolate transport', () {
      final chunks = chunker.chunkSentences('Round trip. Works.');
      final decoded = chunks
          .map((c) => TtsChunk.fromJson(c.toJson()))
          .toList(growable: false);

      expect(decoded, equals(chunks));
    });
  });
}
