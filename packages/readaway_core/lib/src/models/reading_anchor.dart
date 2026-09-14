part of 'models.dart';

/// A stable bookmark that survives font-size, window resize, and reflow changes.
///
/// Anchors are expressed as a chapter index plus a fractional progression
/// within that chapter, so they remain valid even when pagination changes.
@freezed
abstract class ReadingAnchor with _$ReadingAnchor {
  const factory ReadingAnchor({
    /// Zero-based chapter/section index.
    required int chapterIndex,

    /// Reading progress within the chapter, in `[0, 1]`.
    required double progressionInChapter,
  }) = _ReadingAnchor;

  factory ReadingAnchor.fromJson(Map<String, dynamic> json) =>
      _$ReadingAnchorFromJson(json);
}
