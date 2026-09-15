import '../rust/api/models.dart';

/// Word-level span for karaoke-style progressive text highlighting during TTS playback.
class TtsWordSpan {
  final String word;
  final int startOffset;
  final int endOffset;

  const TtsWordSpan({
    required this.word,
    required this.startOffset,
    required this.endOffset,
  });

  factory TtsWordSpan.fromJson(Map<String, dynamic> json) => TtsWordSpan(
        word: json['word'] as String? ?? '',
        startOffset: (json['startOffset'] as num?)?.toInt() ?? 0,
        endOffset: (json['endOffset'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'startOffset': startOffset,
        'endOffset': endOffset,
      };

  @override
  String toString() => 'TtsWordSpan($word: $startOffset..$endOffset)';
}

/// Dart model representing a sentence chunk prepared for speech synthesis and text highlighting.
class TtsChunk {
  final String id;
  final int sectionIndex;
  final int sentenceIndex;
  final String text;
  final String? spokenText;
  final int startOffset;
  final int endOffset;
  final int? rawStartOffset;
  final int? rawEndOffset;
  final bool isParagraphEnd;
  final int paragraphIndex;
  final List<TtsWordSpan> words;
  final String language;
  final int estimatedDurationMs;

  const TtsChunk({
    String? id,
    this.sectionIndex = 0,
    this.sentenceIndex = 0,
    required this.text,
    this.spokenText,
    required this.startOffset,
    required this.endOffset,
    this.rawStartOffset,
    this.rawEndOffset,
    this.isParagraphEnd = false,
    this.paragraphIndex = 0,
    this.words = const [],
    this.language = 'en',
    this.estimatedDurationMs = 0,
  }) : id = id ?? '$sectionIndex:$sentenceIndex:$startOffset';

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
      );

  factory TtsChunk.fromJson(Map<String, dynamic> json) => TtsChunk(
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
        words: (json['words'] as List<dynamic>?)
                ?.whereType<Map<Object?, Object?>>()
                .map((m) => TtsWordSpan.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
        language: json['language'] as String? ?? 'en',
        estimatedDurationMs:
            (json['estimatedDurationMs'] as num?)?.toInt() ?? 0,
      );

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

  @override
  String toString() =>
      'TtsChunk(id: $id, text: "$text", spoken: "$spokenText")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TtsChunk &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          spokenText == other.spokenText &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset;

  @override
  int get hashCode =>
      id.hashCode ^ text.hashCode ^ spokenText.hashCode ^ startOffset.hashCode;
}
