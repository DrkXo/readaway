import '../models/models.dart';
import '../rust/api/tts.dart' as tts_api;

/// High-performance text chunker and speech normalizer backed by native Rust.
class RustTtsChunker {
  const RustTtsChunker._();

  /// Preprocesses text (HTML or plain text) into sentence chunks normalized for TTS narration.
  static List<TtsChunk> chunk({
    required String text,
    int sectionIndex = 0,
    String? language,
    bool isHtml = false,
  }) {
    final rustChunks = tts_api.preprocessTextForTts(
      text: text,
      sectionIndex: sectionIndex,
      language: language,
      isHtml: isHtml,
    );
    return rustChunks.map(TtsChunk.fromRust).toList();
  }

  /// Normalizes a single string for speech (numbers, currency, abbreviations, ASCII transliteration).
  static String normalizeForSpeech(String text) =>
      tts_api.normalizeSingleTextForSpeech(text: text);
}
