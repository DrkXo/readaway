/// Snapshot of the pagination engine state at a point in time.
class PaginationState {
  final int chapterIndex;
  final int pageInChapter;
  final int totalPagesInChapter;
  final int globalPage;
  final int totalPages;
  final double viewportHeight;
  final Map<int, double> chapterHeights;
  final Map<int, int> chapterPageCounts;

  const PaginationState({
    this.chapterIndex = 0,
    this.pageInChapter = 0,
    this.totalPagesInChapter = 1,
    this.globalPage = 0,
    this.totalPages = 0,
    this.viewportHeight = 0.0,
    this.chapterHeights = const {},
    this.chapterPageCounts = const {},
  });

  PaginationState copyWith({
    int? chapterIndex,
    int? pageInChapter,
    int? totalPagesInChapter,
    int? globalPage,
    int? totalPages,
    double? viewportHeight,
    Map<int, double>? chapterHeights,
    Map<int, int>? chapterPageCounts,
  }) {
    return PaginationState(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      pageInChapter: pageInChapter ?? this.pageInChapter,
      totalPagesInChapter: totalPagesInChapter ?? this.totalPagesInChapter,
      globalPage: globalPage ?? this.globalPage,
      totalPages: totalPages ?? this.totalPages,
      viewportHeight: viewportHeight ?? this.viewportHeight,
      chapterHeights: chapterHeights ?? this.chapterHeights,
      chapterPageCounts: chapterPageCounts ?? this.chapterPageCounts,
    );
  }

  @override
  String toString() =>
      'PaginationState(globalPage: $globalPage/$totalPages, chapter: $chapterIndex, page: $pageInChapter/$totalPagesInChapter)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationState &&
          runtimeType == other.runtimeType &&
          chapterIndex == other.chapterIndex &&
          pageInChapter == other.pageInChapter &&
          totalPagesInChapter == other.totalPagesInChapter &&
          globalPage == other.globalPage &&
          totalPages == other.totalPages;

  @override
  int get hashCode =>
      chapterIndex.hashCode ^
      pageInChapter.hashCode ^
      totalPagesInChapter.hashCode ^
      globalPage.hashCode ^
      totalPages.hashCode;
}
