/// Stable anchor representing a reading position within a reflowable document.
class ReadingAnchor {
  final int chapterIndex;
  final double progressionInChapter;

  const ReadingAnchor({
    required this.chapterIndex,
    required this.progressionInChapter,
  });

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
