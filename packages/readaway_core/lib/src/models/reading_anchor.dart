part of 'models.dart';

/// Stable anchor representing a reading position within a reflowable document.
@freezed
sealed class ReadingAnchor with _$ReadingAnchor {
  const factory ReadingAnchor({
    @Default(0) int chapterIndex,
    @Default(0.0) double progressionInChapter,
  }) = _ReadingAnchor;

  factory ReadingAnchor.fromJson(Map<String, dynamic> json) => ReadingAnchor(
    chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
    progressionInChapter:
        (json['progressionInChapter'] as num?)?.toDouble() ?? 0.0,
  );

  @override
  Map<String, dynamic> toJson() => {
    'chapterIndex': chapterIndex,
    'progressionInChapter': progressionInChapter,
  };
}
