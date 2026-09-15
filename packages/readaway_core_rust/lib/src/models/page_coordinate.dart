/// The precise location of a page within a reflowable document.
class PageCoordinate {
  final int chapterIndex;
  final int pageInChapter;
  final int totalPagesInChapter;
  final int globalPage;

  const PageCoordinate({
    required this.chapterIndex,
    required this.pageInChapter,
    required this.totalPagesInChapter,
    required this.globalPage,
  });

  /// Reading progress within the chapter, in `[0, 1]`.
  double get progressionInChapter => totalPagesInChapter > 1
      ? (pageInChapter / (totalPagesInChapter - 1))
      : 0.0;

  @override
  String toString() =>
      'PageCoordinate(chapter: $chapterIndex, page: $pageInChapter/$totalPagesInChapter, global: $globalPage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageCoordinate &&
          runtimeType == other.runtimeType &&
          chapterIndex == other.chapterIndex &&
          pageInChapter == other.pageInChapter &&
          totalPagesInChapter == other.totalPagesInChapter &&
          globalPage == other.globalPage;

  @override
  int get hashCode =>
      chapterIndex.hashCode ^
      pageInChapter.hashCode ^
      totalPagesInChapter.hashCode ^
      globalPage.hashCode;
}
