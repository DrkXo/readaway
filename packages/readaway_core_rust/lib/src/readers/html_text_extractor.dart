import '../abstracts/reflowable_document_reader.dart';
import '../rust/api/tts.dart' as tts_api;

/// High-performance HTML text extractor backed by native Rust.
class HtmlTextExtractor {
  const HtmlTextExtractor._();

  /// Extracts display plain text from [html], stripping tags and non-content elements.
  /// Set [forSpeech], [filterFootnotes], or [swapRubyForSpeech] to format text for TTS audio.
  static String extractPageText(
    String html, {
    bool forSpeech = false,
    bool filterFootnotes = false,
    bool swapRubyForSpeech = false,
  }) {
    if (html.isEmpty) return '';
    if (forSpeech || filterFootnotes || swapRubyForSpeech) {
      return tts_api.extractHtmlContent(html: html).speechText;
    }
    return tts_api.extractHtmlContent(html: html).displayText;
  }

  /// Extracts speech-conditioned plain text from [html], swapping ruby tags
  /// for kana readings and filtering out footnote bodies and citations.
  static String extractSpeechText(String html) =>
      extractPageText(html, forSpeech: true);
}

/// Convenience text-extraction API for reflowable documents.
extension ReflowableSectionText on ReflowableDocumentReader {
  /// Extracts plain text from the section at [index] (for display and analysis).
  String extractSectionText(int index) =>
      HtmlTextExtractor.extractPageText(loadSectionHtml(index));

  /// Extracts speech-conditioned plain text from the section at [index] (for TTS playback).
  String extractSectionSpeechText(int index) =>
      HtmlTextExtractor.extractSpeechText(loadSectionHtml(index));
}

