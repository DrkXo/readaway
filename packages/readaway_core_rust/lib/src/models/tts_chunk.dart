part of 'models.dart';

/// Word-level span for karaoke-style progressive text highlighting during TTS playback.
@freezed
sealed class TtsWordSpan with _$TtsWordSpan {
  const factory TtsWordSpan({
    required String word,
    required int startOffset,
    required int endOffset,
  }) = _TtsWordSpan;

  factory TtsWordSpan.fromJson(Map<String, dynamic> json) => TtsWordSpan(
    word: json['word'] as String? ?? '',
    startOffset: (json['startOffset'] as num?)?.toInt() ?? 0,
    endOffset: (json['endOffset'] as num?)?.toInt() ?? 0,
  );

  @override
  Map<String, dynamic> toJson() => {
    'word': word,
    'startOffset': startOffset,
    'endOffset': endOffset,
  };
}

/// Dart model representing a sentence chunk prepared for speech synthesis and text highlighting.
@freezed
sealed class TtsChunk with _$TtsChunk {
  const TtsChunk._();

  const factory TtsChunk({
    required String id,
    @Default(0) int sectionIndex,
    @Default(0) int sentenceIndex,
    required String text,
    String? spokenText,
    required int startOffset,
    required int endOffset,
    int? rawStartOffset,
    int? rawEndOffset,
    @Default(false) bool isParagraphEnd,
    @Default(0) int paragraphIndex,
    @Default(<TtsWordSpan>[]) List<TtsWordSpan> words,
    @Default('en') String language,
    @Default(0) int estimatedDurationMs,
  }) = _TtsChunk;

  /// Constructs a chunk deriving `id` from `sectionIndex:sentenceIndex:startOffset`
  /// when it is omitted.
  factory TtsChunk.withDerivedId({
    String? id,
    int sectionIndex = 0,
    int sentenceIndex = 0,
    required String text,
    String? spokenText,
    required int startOffset,
    required int endOffset,
    int? rawStartOffset,
    int? rawEndOffset,
    bool isParagraphEnd = false,
    int paragraphIndex = 0,
    List<TtsWordSpan> words = const [],
    String language = 'en',
    int estimatedDurationMs = 0,
  }) => TtsChunk(
    id: id ?? '$sectionIndex:$sentenceIndex:$startOffset',
    sectionIndex: sectionIndex,
    sentenceIndex: sentenceIndex,
    text: text,
    spokenText: spokenText,
    startOffset: startOffset,
    endOffset: endOffset,
    rawStartOffset: rawStartOffset,
    rawEndOffset: rawEndOffset,
    isParagraphEnd: isParagraphEnd,
    paragraphIndex: paragraphIndex,
    words: words,
    language: language,
    estimatedDurationMs: estimatedDurationMs,
  );

  /// Effective text passed to the TTS synthesizer.
  String get speechContent =>
      (spokenText != null && spokenText!.isNotEmpty) ? spokenText! : text;

  /// Character length of the display text.
  int get length => text.length;

  factory TtsChunk.fromRust(RustTtsChunk r) => TtsChunk(
    id: r.id,
    sectionIndex: r.sectionIndex,
    sentenceIndex: r.sentenceIndex,
    text: r.displayText,
    spokenText: r.spokenText,
    startOffset: r.startOffset.toInt(),
    endOffset: r.endOffset.toInt(),
    estimatedDurationMs: r.estimatedDurationMs,
    isParagraphEnd: r.isParagraphEnd,
    paragraphIndex: r.paragraphIndex,
  );

  factory TtsChunk.fromJson(Map<String, dynamic> json) =>
      TtsChunk.withDerivedId(
        id: json['id'] as String?,
        sectionIndex: (json['sectionIndex'] as num?)?.toInt() ?? 0,
        sentenceIndex: (json['sentenceIndex'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        spokenText: json['spokenText'] as String?,
        startOffset: (json['startOffset'] as num?)?.toInt() ?? 0,
        endOffset: (json['endOffset'] as num?)?.toInt() ?? 0,
        rawStartOffset: (json['rawStartOffset'] as num?)?.toInt(),
        rawEndOffset: (json['rawEndOffset'] as num?)?.toInt(),
        isParagraphEnd: json['isParagraphEnd'] as bool? ?? false,
        paragraphIndex: (json['paragraphIndex'] as num?)?.toInt() ?? 0,
        words:
            (json['words'] as List<dynamic>?)
                ?.whereType<Map<Object?, Object?>>()
                .map((m) => TtsWordSpan.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
        language: json['language'] as String? ?? 'en',
        estimatedDurationMs:
            (json['estimatedDurationMs'] as num?)?.toInt() ?? 0,
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'sectionIndex': sectionIndex,
    'sentenceIndex': sentenceIndex,
    'text': text,
    if (spokenText != null) 'spokenText': spokenText,
    'startOffset': startOffset,
    'endOffset': endOffset,
    if (rawStartOffset != null) 'rawStartOffset': rawStartOffset,
    if (rawEndOffset != null) 'rawEndOffset': rawEndOffset,
    'isParagraphEnd': isParagraphEnd,
    'paragraphIndex': paragraphIndex,
    'words': words.map((w) => w.toJson()).toList(),
    'language': language,
    'estimatedDurationMs': estimatedDurationMs,
  };
}
