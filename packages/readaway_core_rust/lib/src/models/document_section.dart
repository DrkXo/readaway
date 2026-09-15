/// A discrete reading section (chapter or spine item) within a reflowable document.
class DocumentSection {
  final String id;
  final int index;
  final String href;
  final String? title;

  const DocumentSection({
    required this.id,
    required this.index,
    required this.href,
    this.title,
  });

  @override
  String toString() =>
      'DocumentSection(index: $index, href: $href, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentSection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          index == other.index &&
          href == other.href;

  @override
  int get hashCode => id.hashCode ^ index.hashCode ^ href.hashCode;
}
