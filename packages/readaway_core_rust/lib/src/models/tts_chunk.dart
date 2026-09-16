import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

import '../rust/api/models.dart';

part 'tts_chunk.g.dart';

/// Word-level span for karaoke-style progressive text highlighting during TTS playback.
@CopyWith()
class TtsWordSpan extends Equatable {
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
  bool get stringify => true;

  @override
  List<Object?> get props => [word, startOffset, endOffset];
}

/// Dart model representing a sentence chunk prepared for speech synthesis and text highlighting.
@CopyWith(constructor: '_')
class TtsChunk extends Equatable {
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

  /// Private constructor used by the generated `copyWith` extension so that
  /// `id` is copied directly (the public constructor derives it from the
  /// section/sentence/offset when omitted).
  const TtsChunk._({
    required this.id,
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
  });

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
    words:
        (json['words'] as List<dynamic>?)
            ?.whereType<Map<Object?, Object?>>()
            .map((m) => TtsWordSpan.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        const [],
    language: json['language'] as String? ?? 'en',
    estimatedDurationMs: (json['estimatedDurationMs'] as num?)?.toInt() ?? 0,
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
  bool get stringify => true;

  @override
  List<Object?> get props => [id, text, spokenText, startOffset, endOffset];
}
