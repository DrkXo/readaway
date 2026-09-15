import '../rust/api/models.dart';

/// A single entry in a document's table of contents / outline.
class OutlineItem {
  final String title;
  final String? href;
  final int level;
  final int? chapterIndex;
  final List<OutlineItem> children;

  const OutlineItem({
    required this.title,
    this.href,
    this.level = 0,
    this.chapterIndex,
    this.children = const [],
  });

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

  @override
  String toString() =>
      'OutlineItem(title: $title, level: $level, chapterIndex: $chapterIndex, children: ${children.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlineItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          href == other.href &&
          level == other.level &&
          chapterIndex == other.chapterIndex;

  @override
  int get hashCode =>
      title.hashCode ^ href.hashCode ^ level.hashCode ^ chapterIndex.hashCode;
}
