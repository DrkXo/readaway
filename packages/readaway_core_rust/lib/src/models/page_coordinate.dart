part of 'models.dart';

/// The precise location of a page within a reflowable document.
@freezed
sealed class PageCoordinate with _$PageCoordinate {
  const PageCoordinate._();

  const factory PageCoordinate({
    required int chapterIndex,
    required int pageInChapter,
    required int totalPagesInChapter,
    required int globalPage,
  }) = _PageCoordinate;

  /// Reading progress within the chapter, in `[0, 1]`.
  double get progressionInChapter => totalPagesInChapter > 1
      ? (pageInChapter / (totalPagesInChapter - 1))
      : 0.0;
}
