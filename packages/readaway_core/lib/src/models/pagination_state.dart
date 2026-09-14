part of 'models.dart';

/// Snapshot of the pagination engine at a point in time.
///
/// Serializable so reading sessions can be restored across launches.
@freezed
abstract class PaginationState with _$PaginationState {
  const factory PaginationState({
    /// Zero-based current chapter index.
    @Default(0) int chapterIndex,

    /// Zero-based current page within the chapter.
    @Default(0) int pageInChapter,

    /// Total pages in the current chapter.
    @Default(1) int totalPagesInChapter,

    /// Zero-based current page across the whole document.
    @Default(0) int globalPage,

    /// Total pages across the whole document.
    @Default(0) int totalPages,

    /// Viewport height used for pagination, in logical pixels.
    @Default(0.0) double viewportHeight,

    /// Laid-out content height per chapter index.
    @Default({}) Map<int, double> chapterHeights,

    /// Computed page count per chapter index.
    @Default({}) Map<int, int> chapterPageCounts,
  }) = _PaginationState;

  factory PaginationState.fromJson(Map<String, dynamic> json) =>
      _$PaginationStateFromJson(json);
}
