import '../rust/api/models.dart';

/// Structured information about an isolated footnote or endnote.
class FootnoteItem {
  final String id;
  final String? referenceId;
  final String? title;
  final String contentHtml;
  final String type;

  const FootnoteItem({
    required this.id,
    this.referenceId,
    this.title,
    required this.contentHtml,
    this.type = 'footnote',
  });

  factory FootnoteItem.fromRust(RustFootnote r) => FootnoteItem(
        id: r.id,
        contentHtml: r.contentHtml,
        type: r.footnoteType,
      );

  factory FootnoteItem.fromJson(Map<String, dynamic> json) => FootnoteItem(
        id: json['id'] as String? ?? '',
        referenceId: json['referenceId'] as String?,
        title: json['title'] as String?,
        contentHtml: json['contentHtml'] as String? ?? '',
        type: json['type'] as String? ?? 'footnote',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (referenceId != null) 'referenceId': referenceId,
        if (title != null) 'title': title,
        'contentHtml': contentHtml,
        'type': type,
      };

  @override
  String toString() => 'FootnoteItem(id: $id, type: $type, title: $title)';
}
