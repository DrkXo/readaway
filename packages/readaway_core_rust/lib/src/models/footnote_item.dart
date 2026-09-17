part of 'models.dart';

/// Structured information about an isolated footnote or endnote.
@freezed
sealed class FootnoteItem with _$FootnoteItem {
  const factory FootnoteItem({
    required String id,
    String? referenceId,
    String? title,
    required String contentHtml,
    @Default('footnote') String type,
  }) = _FootnoteItem;

  factory FootnoteItem.fromRust(RustFootnote r) =>
      FootnoteItem(id: r.id, contentHtml: r.contentHtml, type: r.footnoteType);

  factory FootnoteItem.fromJson(Map<String, dynamic> json) => FootnoteItem(
    id: json['id'] as String? ?? '',
    referenceId: json['referenceId'] as String?,
    title: json['title'] as String?,
    contentHtml: json['contentHtml'] as String? ?? '',
    type: json['type'] as String? ?? 'footnote',
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    if (referenceId != null) 'referenceId': referenceId,
    if (title != null) 'title': title,
    'contentHtml': contentHtml,
    'type': type,
  };
}
