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

  /// Factory recursively mapping native [RustTocItem] to [OutlineItem].
  factory OutlineItem.fromRust(RustTocItem r) => OutlineItem(
    title: r.title,
    href: r.href.isEmpty ? null : r.href,
    level: r.level.toInt(),
    chapterIndex: r.chapterIndex,
    children: r.children.map(OutlineItem.fromRust).toList(),
  );

  /// Returns this item and all descendants in depth-first order.
  List<OutlineItem> flatten() => [
    this,
    for (final child in children) ...child.flatten(),
  ];
}
