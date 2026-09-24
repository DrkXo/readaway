import 'package:equatable/equatable.dart';

/// Represents a segmented sentence with character offset coordinates.
class SentenceSpan extends Equatable {
  final String text;
  final int charStart;
  final int charEnd;
  final int sentenceIndex;

  const SentenceSpan({
    required this.text,
    required this.charStart,
    required this.charEnd,
    required this.sentenceIndex,
  });

  @override
  List<Object?> get props => [text, charStart, charEnd, sentenceIndex];

  @override
  bool? get stringify => true;
}

/// Multi-script sentence segmenter implemented in pure Dart.
class SentenceSegmenter {
  const SentenceSegmenter._();

  static const _zeroWidthRunes = {
    0x200B, // Zero-width space
    0x200C, // Zero-width non-joiner
    0x200D, // Zero-width joiner
    0xFEFF, // Zero-width no-break space / BOM
    0x00AD, // Soft hyphen
  };

  /// Strips zero-width and invisible control characters while preserving structure.
  static String sanitizeUnicode(String text) {
    final runes = <int>[];
    for (final rune in text.runes) {
      if (!_zeroWidthRunes.contains(rune)) {
        runes.add(rune);
      }
    }
    return String.fromCharCodes(runes);
  }

  static final RegExp _titleAbbrRe = RegExp(
    r'\b(?:Dr|Mr|Mrs|Ms|Prof|Sr|Jr|St|Rev|Gen|Col|Capt|Lt|Sgt|vs|e\.g|i\.e)\.\s*',
    caseSensitive: false,
  );

  static final RegExp _decimalNumberRe = RegExp(r'\b\d+\.\d+\b');

  /// Splits [text] into natural sentence boundaries with abbreviation disambiguation
  /// and computes character offsets for each sentence span.
  static List<SentenceSpan> segmentSentences(String text, [String? language]) {
    final sanitized = sanitizeUnicode(text);
    if (sanitized.trim().isEmpty) return const [];

    const maskDot = '\uE000';

    // 1. Mask decimal numbers (e.g. 3.14)
    var masked = sanitized.replaceAllMapped(_decimalNumberRe, (m) {
      return m.group(0)!.replaceAll('.', maskDot);
    });

    // 2. Mask title abbreviations (e.g. Dr., Mr., vs., e.g., i.e.)
    masked = masked.replaceAllMapped(_titleAbbrRe, (m) {
      return m.group(0)!.replaceAll('.', maskDot);
    });

    // 3. Mask name initials followed by a space and capital letter (e.g. J. K. Rowling)
    masked = masked.replaceAllMapped(RegExp(r'\b([A-Z])\.\s+(?=[A-Z])'), (m) {
      return '${m.group(1)}$maskDot ';
    });

    // 4. Split on sentence terminals:
    // - Western punctuation (. ! ?) followed by whitespace, quotes, or end of line
    // - CJK punctuation (。 ！ ？) with or without trailing whitespace
    // - Ellipses (…) followed by whitespace or CJK char
    // - Newlines
    final boundaryRe = RegExp(r'(?<=[.!?])\s+|(?<=[。！？])\s*|(?<=[…])\s+|\n+');

    final matches = boundaryRe.allMatches(masked).toList();
    final spans = <SentenceSpan>[];
    var currentStart = 0;

    void addSpan(int rawStart, int rawEnd) {
      if (rawStart >= rawEnd) return;
      final rawSub = sanitized.substring(rawStart, rawEnd);
      final trimmedSub = rawSub.trim();
      if (trimmedSub.isEmpty) return;

      final leadingTrim = rawSub.indexOf(trimmedSub);
      final effectiveStart = rawStart + (leadingTrim != -1 ? leadingTrim : 0);
      final effectiveEnd = effectiveStart + trimmedSub.length;

      spans.add(
        SentenceSpan(
          text: trimmedSub,
          charStart: effectiveStart,
          charEnd: effectiveEnd,
          sentenceIndex: spans.length,
        ),
      );
    }

    for (final match in matches) {
      addSpan(currentStart, match.start);
      currentStart = match.end;
    }

    if (currentStart < sanitized.length) {
      addSpan(currentStart, sanitized.length);
    }

    return spans;
  }
}
