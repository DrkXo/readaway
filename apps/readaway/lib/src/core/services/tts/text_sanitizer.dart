/// Utility for speech sanitization, noise filtering, and text normalization
/// tailored for neural TTS synthesis engines (Sherpa ONNX Kokoro, VITS, Matcha).
class TextSanitizer {
  TextSanitizer._();

  /// Regex detecting unpronounceable ornamental symbols, horizontal rules, and pure punctuation.
  /// Matches strings composed entirely of punctuation, symbols, whitespace, or ASCII control chars.
  static final RegExp _unspeakablePattern = RegExp(
    r'^[\s\p{P}\p{S}\x00-\x1F\x7F]+$',
    unicode: true,
  );

  /// Letters and numbers across Latin, CJK, Cyrillic, Arabic, Greek, and other scripts.
  static final RegExp _speechCharactersPattern = RegExp(
    r'[\p{L}\p{N}]',
    unicode: true,
  );

  /// Inline reading annotations / furigana heuristics (similar to Readest inlineAnnotations):
  /// e.g. 漢字（かんじ）, 漢(かん), 漢《かん》
  static final RegExp _inlineReadingPattern = RegExp(
    r'([\p{Unified_Ideograph}\u3005\u3006\u3007\u303b])(?:（[\p{Unified_Ideograph}\u3005\u3006\u3007\u303bぁ-ゖ゛-ゟァ-ヿ]+）|\([\p{Unified_Ideograph}\u3005\u3006\u3007\u303bぁ-ゖ゛-ゟァ-ヿ]+\)|《[\p{Unified_Ideograph}\u3005\u3006\u3007\u303bぁ-ゖ゛-ゟァ-ヿ]+》)',
    unicode: true,
  );

  /// Bracketed footnote and citation reference markers (e.g. "[1]", "[23]", "(1)", "(note 1)").
  static final RegExp _footnoteReferencePattern = RegExp(
    r'\[\s*(?:\d+|[a-z]|\*|dagger)\s*\]|\(\s*\d+\s*\)',
    caseSensitive: false,
  );

  /// Broken word hyphens at line wraps frequently produced by PDF text extractors (e.g. "con-\nnection").
  static final RegExp _lineWrapHyphenPattern = RegExp(
    r'(\b[a-zA-Z]{2,})-\s*\r?\n\s*([a-zA-Z]{2,}\b)',
  );

  /// Invisible or zero-width Unicode characters that cause tokenizer failures or awkward speech gaps.
  static final RegExp _invisibleCharactersPattern = RegExp(
    r'[\u00ad\u200b\u200c\u200d\u200e\u200f\ufeff\u2060]',
  );

  /// Excessive repeated punctuation marks (e.g. "????", "!!!!", "....").
  static final RegExp _excessivePunctuationPattern = RegExp(
    r'([!?.]){3,}',
  );

  /// Returns true if [text] contains speakable phonetic content (words, numbers, letters).
  ///
  /// Rejects ornamental dividers (e.g. "* * *", "---", "==="), bullet points, and pure symbol lines.
  static bool isSpeakable(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (_unspeakablePattern.hasMatch(trimmed)) return false;
    return _speechCharactersPattern.hasMatch(trimmed);
  }

  /// Sanitizes and normalizes [text] for optimal TTS synthesis while preserving meaning.
  static String sanitizeForSpeech(String text) {
    if (text.isEmpty) return text;

    var sanitized = text;

    // 1. Remove invisible Unicode characters & soft hyphens
    sanitized = sanitized.replaceAll(_invisibleCharactersPattern, '');

    // 2. Repair hyphenated line breaks from PDF/EPUB extractors
    sanitized = sanitized.replaceAllMapped(_lineWrapHyphenPattern, (m) {
      return '${m[1]}${m[2]}';
    });

    // 3. Strip CJK inline reading annotations (keep the base ideograph)
    sanitized = sanitized.replaceAllMapped(_inlineReadingPattern, (m) {
      return m[1] ?? '';
    });

    // 4. Strip footnote & citation anchors (e.g. "[1]", "[12]")
    sanitized = sanitized.replaceAll(_footnoteReferencePattern, '');

    // 5. Normalize smart quotes, apostrophes, and dashes for TTS phonemizer
    sanitized = sanitized
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('—', ' - ')
        .replaceAll('–', ' - ');

    // 6. Simplify repeated punctuation
    sanitized = sanitized.replaceAllMapped(_excessivePunctuationPattern, (m) {
      final char = m[1]!;
      return char == '.' ? '...' : char;
    });

    // 7. Collapse multiple whitespace and linebreaks into single spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return sanitized;
  }
}
