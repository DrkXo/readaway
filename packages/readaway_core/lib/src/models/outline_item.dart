part of 'models.dart';

/// A single entry in a document's table of contents / outline.
///
/// The outline is represented as a tree via [children]; use [flatten] to
/// obtain a depth-first, flat list (e.g. for rendering a linear TOC).
@freezed
abstract class OutlineItem with _$OutlineItem {
  const factory OutlineItem({
    /// Display label of the outline entry.
    required String title,

    /// Target href within the document, if any.
    String? href,

    /// Nesting depth (0 = top level).
    @Default(0) int level,

    /// Index of the section/chapter this entry targets, if resolvable.
    int? chapterIndex,

    /// Nested child entries.
    @Default([]) List<OutlineItem> children,
  }) = _OutlineItem;

  factory OutlineItem.fromJson(Map<String, dynamic> json) =>
      _$OutlineItemFromJson(json);

  const OutlineItem._();

  /// Returns this item and all descendants in depth-first order.
  List<OutlineItem> flatten() => [
    this,
    for (final child in children) ...child.flatten(),
  ];
}
