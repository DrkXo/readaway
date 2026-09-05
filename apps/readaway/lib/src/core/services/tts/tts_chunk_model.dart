/// Word-level span for karaoke or progressive text highlighting during TTS playback.
class TtsWordSpan {
  const TtsWordSpan({
    required this.word,
    required this.startOffset,
    required this.endOffset,
  });

  /// The raw word or token string.
  final String word;

  /// Absolute character index start bound in source chunk.
  final int startOffset;

  /// Absolute character index end bound in source chunk.
  final int endOffset;

  Map<String, dynamic> toMap() => {
        'word': word,
        'startOffset': startOffset,
        'endOffset': endOffset,
      };

  factory TtsWordSpan.fromMap(Map<dynamic, dynamic> map) {
    return TtsWordSpan(
      word: map['word'] as String? ?? '',
      startOffset: map['startOffset'] as int? ?? 0,
      endOffset: map['endOffset'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'TtsWordSpan($word, $startOffset..$endOffset)';
}

/// Represents a single sentence, clause, or utterance payload for TTS synthesis
/// and UI text highlighting.
class TtsChunk {
  const TtsChunk({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    this.spokenText,
    this.rawStartOffset,
    this.rawEndOffset,
    this.isParagraphEnd = false,
    this.paragraphIndex = 0,
    this.words = const [],
  });

  /// Trimmed display text representing the sentence or clause.
  final String text;

  /// Text sanitized and normalized for speech synthesis (e.g. stripped of footnote
  /// citations, soft hyphens, and decorative glyphs).
  ///
  /// Defaults to [text] if not explicitly provided.
  final String? spokenText;

  /// Effective text passed to the TTS synthesizer.
  String get speechContent =>
      (spokenText != null && spokenText!.isNotEmpty) ? spokenText! : text;

  /// Absolute character index start bound in the source text (trimmed to non-whitespace).
  final int startOffset;

  /// Absolute character index end bound in the source text (trimmed to non-whitespace).
  final int endOffset;

  /// Absolute character index start bound in the source text including leading whitespace.
  final int? rawStartOffset;

  /// Absolute character index end bound in the source text including trailing whitespace.
  final int? rawEndOffset;

  /// Whether this chunk marks the terminal sentence/clause of a paragraph.
  final bool isParagraphEnd;

  /// 0-based paragraph index within the page or document section.
  final int paragraphIndex;

  /// Optional word-level spans for progressive karaoke-style highlighting.
  final List<TtsWordSpan> words;

  /// Length of the displayed text.
  int get length => text.length;

  /// Creates a copy of this chunk with updated fields.
  TtsChunk copyWith({
    String? text,
    String? spokenText,
    int? startOffset,
    int? endOffset,
    int? rawStartOffset,
    int? rawEndOffset,
    bool? isParagraphEnd,
    int? paragraphIndex,
    List<TtsWordSpan>? words,
  }) {
    return TtsChunk(
      text: text ?? this.text,
      spokenText: spokenText ?? this.spokenText,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      rawStartOffset: rawStartOffset ?? this.rawStartOffset,
      rawEndOffset: rawEndOffset ?? this.rawEndOffset,
      isParagraphEnd: isParagraphEnd ?? this.isParagraphEnd,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      words: words ?? this.words,
    );
  }

  /// Converts this [TtsChunk] into a primitive Map suitable for SendPort transmission.
  Map<String, dynamic> toMap() => {
        'text': text,
        'spokenText': spokenText,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'rawStartOffset': rawStartOffset ?? startOffset,
        'rawEndOffset': rawEndOffset ?? endOffset,
        'isParagraphEnd': isParagraphEnd,
        'paragraphIndex': paragraphIndex,
        'words': words.map((w) => w.toMap()).toList(growable: false),
      };

  /// Deserializes a [TtsChunk] from an isolate response Map.
  factory TtsChunk.fromMap(Map<dynamic, dynamic> map) {
    final rawWords = map['words'] as List<dynamic>?;
    return TtsChunk(
      text: map['text'] as String? ?? '',
      spokenText: map['spokenText'] as String?,
      startOffset: map['startOffset'] as int? ?? 0,
      endOffset: map['endOffset'] as int? ?? 0,
      rawStartOffset: map['rawStartOffset'] as int?,
      rawEndOffset: map['rawEndOffset'] as int?,
      isParagraphEnd: map['isParagraphEnd'] as bool? ?? false,
      paragraphIndex: map['paragraphIndex'] as int? ?? 0,
      words: rawWords != null
          ? rawWords
              .whereType<Map<dynamic, dynamic>>()
              .map((w) => TtsWordSpan.fromMap(w))
              .toList(growable: false)
          : const [],
    );
  }

  @override
  String toString() =>
      'TtsChunk("$text", $startOffset..$endOffset, pEnd: $isParagraphEnd, pIdx: $paragraphIndex)';
}
