import '../models/models.dart';
import '../rust/api/tts.dart' as tts_api;

/// High-performance multi-script text chunking engine backed by native Rust.
class TextChunker {
  const TextChunker();

  /// Chunks [text] into normalized [TtsChunk]s.
  List<TtsChunk> chunkSentences(
    String text, {
    int maxChunkChars = 350,
    bool sanitizeForSpeech = true,
    int sectionIndex = 0,
    String language = 'en',
  }) {
    if (text.trim().isEmpty) return const [];

    try {
      final rustChunks = tts_api.preprocessTextForTts(
        text: text,
        sectionIndex: sectionIndex,
        language: language,
        isHtml: text.contains('<') && text.contains('>'),
      );

      final chunks = rustChunks.map(TtsChunk.fromRust).toList();
      if (chunks.isEmpty) return _fallbackChunk(text, sectionIndex);

      if (maxChunkChars <= 0) return chunks;

      final results = <TtsChunk>[];
      for (final chunk in chunks) {
        if (chunk.text.length <= maxChunkChars) {
          results.add(chunk);
        } else {
          results.addAll(_splitOversized(chunk, maxChunkChars));
        }
      }
      return results;
    } catch (_) {
      return _fallbackChunk(text, sectionIndex);
    }
  }

  List<TtsChunk> _splitOversized(TtsChunk chunk, int maxChars) {
    final text = chunk.text;
    final results = <TtsChunk>[];
    var start = 0;

    while (start < text.length) {
      var end = start + maxChars;
      if (end >= text.length) {
        end = text.length;
      } else {
        // Try to break at whitespace or punctuation
        final lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start + 50) {
          end = lastSpace;
        }
      }

      final subText = text.substring(start, end).trim();
      if (subText.isNotEmpty) {
        results.add(
          TtsChunk.withDerivedId(
            sectionIndex: chunk.sectionIndex,
            sentenceIndex: chunk.sentenceIndex + results.length,
            text: subText,
            spokenText: subText,
            startOffset: chunk.startOffset + start,
            endOffset: chunk.startOffset + end,
            isParagraphEnd: end >= text.length && chunk.isParagraphEnd,
            language: chunk.language,
          ),
        );
      }
      start = end + 1;
    }

    return results;
  }

  List<TtsChunk> _fallbackChunk(String text, int sectionIndex) {
    final sentences = text.split(RegExp(r'(?<=[.!?。！？])\s+'));
    final results = <TtsChunk>[];
    var offset = 0;

    for (int i = 0; i < sentences.length; i++) {
      final s = sentences[i].trim();
      if (s.isEmpty) continue;
      final start = text.indexOf(s, offset);
      final end = start + s.length;
      offset = end;

      results.add(
        TtsChunk.withDerivedId(
          sectionIndex: sectionIndex,
          sentenceIndex: i,
          text: s,
          spokenText: s,
          startOffset: start != -1 ? start : 0,
          endOffset: start != -1 ? end : s.length,
        ),
      );
    }
    return results;
  }
}
