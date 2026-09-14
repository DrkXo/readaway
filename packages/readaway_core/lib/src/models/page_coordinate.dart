part of 'models.dart';

/// The precise location of a page within a reflowable document.
@freezed
abstract class PageCoordinate with _$PageCoordinate {
  const factory PageCoordinate({
    /// Zero-based chapter/section index.
    required int chapterIndex,

    /// Zero-based page within the chapter.
    required int pageInChapter,

    /// Total number of pages in the chapter.
    required int totalPagesInChapter,

    /// Zero-based page across the whole document.
    required int globalPage,
  }) = _PageCoordinate;

  factory PageCoordinate.fromJson(Map<String, dynamic> json) =>
      _$PageCoordinateFromJson(json);

  const PageCoordinate._();

  /// Reading progress within the chapter, in `[0, 1]`.
  double get progressionInChapter => totalPagesInChapter > 1
      ? (pageInChapter / (totalPagesInChapter - 1))
      : 0.0;
}
