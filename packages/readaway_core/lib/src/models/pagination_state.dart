part of 'models.dart';

/// Snapshot of the pagination engine state at a point in time.
@freezed
sealed class PaginationState with _$PaginationState {
  const factory PaginationState({
    @Default(0) int chapterIndex,
    @Default(0) int pageInChapter,
    @Default(1) int totalPagesInChapter,
    @Default(0) int globalPage,
    @Default(0) int totalPages,
    @Default(0.0) double viewportHeight,
    @Default(<int, double>{}) Map<int, double> chapterHeights,
    @Default(<int, int>{}) Map<int, int> chapterPageCounts,
  }) = _PaginationState;
}
