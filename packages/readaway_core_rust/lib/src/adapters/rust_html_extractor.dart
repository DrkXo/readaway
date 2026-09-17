import '../rust/api/models.dart';
import '../rust/api/tts.dart' as tts_api;

/// High-performance HTML text and footnote extractor backed by Rust.
class RustHtmlExtractor {
  const RustHtmlExtractor._();

  /// Extracts display text, spoken text, and structured footnotes from [html].
  static RustExtractedContent extract(String html) =>
      tts_api.extractHtmlContent(html: html);

  /// Extracts clean text suitable for screen display.
  static String extractDisplayText(String html) =>
      tts_api.extractHtmlContent(html: html).displayText;

  /// Extracts clean text conditioned for natural TTS narration.
  static String extractSpeechText(String html) =>
      tts_api.extractHtmlContent(html: html).speechText;
}
