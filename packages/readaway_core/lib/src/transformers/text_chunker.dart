import '../models/models.dart';
import '../tts/tts_chunker.dart';

/// Multi-script text chunking engine implemented in pure Dart.
class TextChunker {
  const TextChunker();

  /// Chunks [text] into normalized [TtsChunk]s.
  List<TtsChunk> chunkSentences(
    String text, {
    int maxChunkChars = 450,
    bool sanitizeForSpeech = true,
    int sectionIndex = 0,
    String language = 'en',
  }) {
    if (text.trim().isEmpty) return const [];

    return TtsChunker.preprocessText(
      text: text,
      sectionIndex: sectionIndex,
      language: language,
      isHtml: text.contains('<') && text.contains('>'),
      maxParagraphChunkChars: maxChunkChars,
    );
  }
}
