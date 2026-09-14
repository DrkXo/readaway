/// Utilities for speech sanitization, noise filtering, and text normalization
/// tailored for neural TTS synthesis engines (Sherpa ONNX Kokoro, VITS, Matcha).
///
/// Instances are `const` and stateless, so allocating one is free. Every
/// expensive artefact lives in [_SpeechPatterns] and is compiled once per
/// isolate, shared by all instances.
class TextSanitizer {
  /// Creates a stateless sanitizer.
  const TextSanitizer();

  /// Reports whether [text] carries speakable phonetic content (letters or
  /// digits).
  ///
  /// Returns `false` for ornamental dividers (e.g. `* * *`, `---`, `===`),
  /// bullet-only lines, and blank input.
  bool isSpeakable(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (_SpeechPatterns.unspeakable.hasMatch(trimmed)) return false;
    return _SpeechPatterns.speechCharacter.hasMatch(trimmed);
  }

  /// Normalizes [text] for optimal TTS synthesis while preserving meaning.
  ///
  /// Strips invisible characters, repairs hyphenated line breaks, removes CJK
  /// ruby readings and footnote anchors, folds smart punctuation, dampens
  /// runaway punctuation, and collapses whitespace runs.
  String sanitizeForSpeech(String text) {
    if (text.isEmpty) return text;

    var sanitized = text;

    // 1. Remove invisible Unicode characters & soft hyphens
    sanitized = sanitized.replaceAll(_SpeechPatterns.invisibleCharacter, '');

    // 2. Repair hyphenated line breaks from PDF/EPUB extractors
    sanitized = sanitized.replaceAllMapped(_SpeechPatterns.lineWrapHyphen, (m) {
      return '${m[1]}${m[2]}';
    });

    // 3. Strip CJK inline reading annotations (keep the base ideograph)
    sanitized = sanitized.replaceAllMapped(_SpeechPatterns.inlineReading, (m) {
      return m[1] ?? '';
    });

    // 4. Strip footnote & citation anchors (e.g. "[1]", "[12]")
    sanitized = sanitized.replaceAll(_SpeechPatterns.footnoteReference, '');

    // 5. Normalize smart quotes, apostrophes, and dashes for TTS phonemizer
    sanitized = sanitized
        .replaceAll('\u201c', '"')
        .replaceAll('\u201d', '"')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u2014', ' - ')
        .replaceAll('\u2013', ' - ');

    // 6. Simplify repeated punctuation
    sanitized = sanitized.replaceAllMapped(
      _SpeechPatterns.excessivePunctuation,
      (m) {
        final char = m[1]!;
        return char == '.' ? '...' : char;
      },
    );

    // 7. Collapse multiple whitespace and linebreaks into single spaces
    sanitized = sanitized.replaceAll(_SpeechPatterns.whitespaceRun, ' ').trim();

    return sanitized;
  }

  /// Infers a BCP-47 language tag from the dominant script in [text].
  ///
  /// Detection precedence favours scripts carrying unambiguous signals: kana
  /// implies Japanese, Hangul implies Korean, lone Han implies Chinese, then
  /// Cyrillic/Greek/Arabic/Hebrew/Devanagari, finally Latin (`'en'`).
  String inferLanguage(String text) {
    if (text.isEmpty) return 'en';

    // Japanese: presence of kana (hiragana/katakana) is definitive.
    if (_SpeechPatterns.kana.hasMatch(text)) return 'ja';

    // Korean: Hangul syllables or conjoining jamo.
    if (_SpeechPatterns.hangul.hasMatch(text)) return 'ko';

    // Chinese: Han ideographs (basic + Extension A) without kana/Hangul.
    if (_SpeechPatterns.hanIdeograph.hasMatch(text)) return 'zh';

    // Cyrillic → ru (widest shipped TTS voice family).
    if (_SpeechPatterns.cyrillic.hasMatch(text)) return 'ru';

    // Greek
    if (_SpeechPatterns.greek.hasMatch(text)) return 'el';

    // Arabic
    if (_SpeechPatterns.arabic.hasMatch(text)) return 'ar';

    // Hebrew
    if (_SpeechPatterns.hebrew.hasMatch(text)) return 'he';

    // Devanagari (Hindi, Sanskrit, Marathi, Nepali)
    if (_SpeechPatterns.devanagari.hasMatch(text)) return 'hi';

    // Default to English (Latin script)
    return 'en';
  }
}

/// Process-wide, lazily-compiled pattern cache backing [TextSanitizer].
///
/// Keeping the artefacts here means the public class stays `const` and
/// allocation-free while each `RegExp` is still built exactly once.
abstract final class _SpeechPatterns {
  /// Strings composed entirely of punctuation, symbols, whitespace, or ASCII
  /// control characters — ornamental dividers and bullet-only lines.
  static final RegExp unspeakable = RegExp(
    r'^[\s\p{P}\p{S}\x00-\x1F\x7F]+$',
    unicode: true,
  );

  /// Letters and numbers across Latin, CJK, Cyrillic, Arabic, Greek, and other
  /// scripts.
  static final RegExp speechCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Inline reading annotations / furigana heuristics —
  /// e.g. 漢字（かんじ）, 漢(かん), 漢《かん》.
  static final RegExp inlineReading = RegExp(
    r'([\p{Unified_Ideograph}\u3005\u3006\u3007\u303b])(?:（[\p{Unified_Ideograph}\u3005\u3006\u3007\u303bぁ-ゖ゛-ゟァ-ヿ]+）|\([\p{Unified_Ideograph}\u3005\u3006\u3007\u303bぁ-ゖ゛-ゟァ-ヿ]+\)|《[\p{Unified_Ideograph}\u3005\u3006\u3007\u303bぁ-ゖ゛-ゟァ-ヿ]+》)',
    unicode: true,
  );

  /// Bracketed footnote and citation reference markers —
  /// e.g. `"[1]"`, `"(23)"`.
  static final RegExp footnoteReference = RegExp(
    r'\[\s*(?:\d+|[a-z]|\*|dagger)\s*\]|\(\s*\d+\s*\)',
    caseSensitive: false,
  );

  /// Hyphenated line wraps produced by PDF text extractors —
  /// e.g. `"con-\nnection"`.
  static final RegExp lineWrapHyphen = RegExp(
    r'(\b[a-zA-Z]{2,})-\s*\r?\n\s*([a-zA-Z]{2,}\b)',
  );

  /// Zero-width and invisible Unicode characters that derail tokenizers.
  static final RegExp invisibleCharacter = RegExp(
    r'[\u00ad\u200b\u200c\u200d\u200e\u200f\ufeff\u2060]',
  );

  /// Runs of three or more identical sentence terminators — e.g. `"????"`.
  static final RegExp excessivePunctuation = RegExp(r'([!?.]){3,}');

  /// Any run of whitespace, collapsed to a single space.
  static final RegExp whitespaceRun = RegExp(r'\s+');

  /// Hiragana and katakana.
  static final RegExp kana = RegExp(r'[\u3040-\u309f\u30a0-\u30ff]');

  /// Hangul syllables and conjoining jamo.
  static final RegExp hangul = RegExp(r'[\u1100-\u11ff\uac00-\ud7af]');

  /// Han ideographs (basic block + Extension A).
  static final RegExp hanIdeograph = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff]');

  /// Cyrillic.
  static final RegExp cyrillic = RegExp(r'[\u0400-\u04ff]');

  /// Greek.
  static final RegExp greek = RegExp(r'[\u0370-\u03ff]');

  /// Arabic.
  static final RegExp arabic = RegExp(r'[\u0600-\u06ff]');

  /// Hebrew.
  static final RegExp hebrew = RegExp(r'[\u0590-\u05ff]');

  /// Devanagari.
  static final RegExp devanagari = RegExp(r'[\u0900-\u097f]');
}
