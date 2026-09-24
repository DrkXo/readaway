part of 'models.dart';

/// A single entry in a document's table of contents / outline.
@freezed
sealed class OutlineItem with _$OutlineItem {
  const OutlineItem._();

  const factory OutlineItem({
    required String title,
    String? href,
    @Default(0) int level,
    int? chapterIndex,
    @Default(<OutlineItem>[]) List<OutlineItem> children,
  }) = _OutlineItem;

  /// Returns this item and all descendants in depth-first order.
  List<OutlineItem> flatten() => [
    this,
    for (final child in children) ...child.flatten(),
  ];
}
