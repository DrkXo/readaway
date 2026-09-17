import '../models/models.dart';
import '../readers/html_text_extractor.dart';
import '../tts/sentence_segmenter.dart';
import '../tts/speech_normalizer.dart';
import '../tts/tts_chunker.dart';

/// Fluent string extensions for HTML parsing, text extraction, and entity decoding.
extension ReadAwayHtmlStringX on String {
  /// Extracts clean display or spoken text from this HTML/XHTML string.
  ///
  /// When [forSpeech], [filterFootnotes], or [swapRubyForSpeech] is true:
  /// - Strips footnote content and numeric citation links (`[1]`, `*`).
  /// - Swaps Japanese `<ruby>` kanji with `<rt>` kana readings if kana is present.
  /// - Converts block boundaries to newlines.
  String extractPageText({
    bool forSpeech = false,
    bool filterFootnotes = false,
    bool swapRubyForSpeech = false,
  }) => HtmlTextExtractor.extractPageText(
    this,
    forSpeech: forSpeech,
    filterFootnotes: filterFootnotes,
    swapRubyForSpeech: swapRubyForSpeech,
  );

  /// Extracts speech-optimized text from this HTML/XHTML string (with footnotes stripped
  /// and ruby readings swapped).
  String extractSpeechText() => HtmlTextExtractor.extractSpeechText(this);

  /// Extracts structured footnote items declared via `<aside>` or Duokan/Weread tags.
  List<FootnoteItem> extractFootnotes() =>
      HtmlTextExtractor.extractFootnotes(this);

  /// Decodes HTML entities (e.g. `&amp;`, `&quot;`, `&#1234;`, `&#x1F600;`) into plain text.
  String decodeHtmlEntities() => HtmlTextExtractor.decodeHtmlEntities(this);
}

/// Fluent string extensions for speech normalization, TTS tokenization, and sentence segmentation.
extension ReadAwaySpeechStringX on String {
  /// Fully normalizes this text for speech synthesis (expanding currency, percentages,
  /// ordinals, abbreviations, and numbers).
  String normalizeForSpeech() => SpeechNormalizer.normalizeForSpeech(this);

  /// Splits this text into sentence spans with character offsets.
  List<SentenceSpan> segmentSentences([String? language]) =>
      SentenceSegmenter.segmentSentences(this, language);

  /// Sanitizes zero-width, invisible, and format characters.
  String sanitizeUnicode() => SentenceSegmenter.sanitizeUnicode(this);

  /// Expands currency symbols and standalone numbers into spoken words.
  String expandNumbersAndCurrency() =>
      SpeechNormalizer.expandNumbersAndCurrency(this);

  /// Expands common abbreviations (e.g. `Dr.` -> `Doctor`, `kg` -> `kilograms`).
  String expandAbbreviations() => SpeechNormalizer.expandAbbreviations(this);

  /// Whether Latin characters are dominant in this text.
  bool isLatinDominant() => SpeechNormalizer.isLatinDominant(this);

  /// Estimates spoken duration in milliseconds for this text at given [wordsPerMinute].
  int estimateSpeechDurationMs([double? wordsPerMinute]) =>
      SpeechNormalizer.estimateDurationMs(this, wordsPerMinute);

  /// Preprocesses this text into TTS chunks suitable for synthesis.
  List<TtsChunk> preprocessTtsChunks({
    int sectionIndex = 0,
    String? language,
    bool isHtml = false,
    int maxParagraphChunkChars = TtsChunker.defaultMaxParagraphChunkChars,
  }) => TtsChunker.preprocessText(
    text: this,
    sectionIndex: sectionIndex,
    language: language,
    isHtml: isHtml,
    maxParagraphChunkChars: maxParagraphChunkChars,
  );
}
