part of 'models.dart';

/// Word-level span for karaoke-style progressive text highlighting during TTS playback.
@freezed
abstract class TtsWordSpan with _$TtsWordSpan {
  const factory TtsWordSpan({
    /// The raw word or token string.
    required String word,

    /// Absolute character index start bound within the parent chunk text.
    required int startOffset,

    /// Absolute character index end bound within the parent chunk text.
    required int endOffset,
  }) = _TtsWordSpan;

  factory TtsWordSpan.fromJson(Map<String, dynamic> json) =>
      _$TtsWordSpanFromJson(json);
}

/// Represents a single sentence, clause, or utterance payload for TTS synthesis
/// and UI text highlighting.
///
/// Each chunk carries display text, optional speech-only text, exact character
/// offsets for bidirectional sync, paragraph metadata, word-level spans, and a
/// BCP-47 language tag inferred from the dominant script.
@freezed
abstract class TtsChunk with _$TtsChunk {
  const TtsChunk._();

  const factory TtsChunk({
    /// Trimmed display text representing the sentence or clause.
    required String text,

    /// Absolute character index start bound in the source text
    /// (trimmed to non-whitespace).
    required int startOffset,

    /// Absolute character index end bound in the source text
    /// (trimmed to non-whitespace).
    required int endOffset,

    /// Text sanitized and normalized for speech synthesis (e.g. stripped of
    /// footnote citations, soft hyphens, and decorative glyphs).
    ///
    /// Falls back to [text] at read time via [speechContent].
    String? spokenText,

    /// Absolute character index start bound in the source text including
    /// leading whitespace.
    int? rawStartOffset,

    /// Absolute character index end bound in the source text including
    /// trailing whitespace.
    int? rawEndOffset,

    /// Whether this chunk marks the terminal sentence/clause of a paragraph.
    @Default(false) bool isParagraphEnd,

    /// 0-based paragraph index within the page or document section.
    @Default(0) int paragraphIndex,

    /// Optional word-level spans for progressive karaoke-style highlighting.
    ///
    /// Explicit encoders keep the nested [TtsWordSpan] objects flattened into
    /// plain maps so the payload survives `SendPort` hops between isolates.
    @JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans)
    @Default(<TtsWordSpan>[])
    List<TtsWordSpan> words,

    /// BCP-47 language tag inferred from the chunk's dominant script
    /// (e.g. `'en'`, `'ja'`, `'zh'`, `'ru'`).
    ///
    /// Lets the TTS engine pick the right voice/pronunciation for
    /// mixed-language content.
    @Default('en') String language,
  }) = _TtsChunk;

  factory TtsChunk.fromJson(Map<String, dynamic> json) =>
      _$TtsChunkFromJson(json);

  /// Effective text passed to the TTS synthesizer.
  ///
  /// Returns [spokenText] when it is non-null and non-empty, otherwise
  /// falls back to the display [text].
  String get speechContent =>
      (spokenText != null && spokenText!.isNotEmpty) ? spokenText! : text;

  /// Character length of the display [text].
  int get length => text.length;
}

/// Flattens [TtsWordSpan]s into plain maps for JSON/`SendPort` transport.
List<Map<String, dynamic>> _encodeWordSpans(List<TtsWordSpan> spans) =>
    spans.map((span) => span.toJson()).toList(growable: false);

/// Revives [TtsWordSpan]s from a transported JSON list.
List<TtsWordSpan> _decodeWordSpans(Object? json) {
  if (json is! List) return const <TtsWordSpan>[];
  return json
      .whereType<Map<Object?, Object?>>()
      .map((entry) => TtsWordSpan.fromJson(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
}
