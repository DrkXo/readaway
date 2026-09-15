/// Stable anchor representing a reading position within a reflowable document.
class ReadingAnchor {
  final int chapterIndex;
  final double progressionInChapter;

  const ReadingAnchor({
    required this.chapterIndex,
    required this.progressionInChapter,
  });

  ReadingAnchor copyWith({
    int? chapterIndex,
    double? progressionInChapter,
  }) {
    return ReadingAnchor(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      progressionInChapter: progressionInChapter ?? this.progressionInChapter,
    );
  }

  factory ReadingAnchor.fromJson(Map<String, dynamic> json) => ReadingAnchor(
        chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
        progressionInChapter:
            (json['progressionInChapter'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'chapterIndex': chapterIndex,
        'progressionInChapter': progressionInChapter,
      };

  @override
  String toString() =>
      'ReadingAnchor(chapterIndex: $chapterIndex, progressionInChapter: $progressionInChapter)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingAnchor &&
          runtimeType == other.runtimeType &&
          chapterIndex == other.chapterIndex &&
          progressionInChapter == other.progressionInChapter;

  @override
  int get hashCode => chapterIndex.hashCode ^ progressionInChapter.hashCode;
}
