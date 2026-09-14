part of 'models.dart';

/// Structured information about an isolated footnote or endnote.
@freezed
abstract class FootnoteItem with _$FootnoteItem {
  const factory FootnoteItem({
    /// Unique anchor identifier of the footnote body (e.g. `fn-1`).
    required String id,

    /// Identifier of the caller reference link if present.
    String? referenceId,

    /// Human-readable title or label of the footnote (e.g. `[1]`, `Note 1`).
    String? title,

    /// Clean inner HTML content of the footnote body.
    required String contentHtml,

    /// Semantic type of note: 'footnote', 'endnote', 'rearnote', or 'note'.
    @Default('footnote') String type,
  }) = _FootnoteItem;

  factory FootnoteItem.fromJson(Map<String, dynamic> json) =>
      _$FootnoteItemFromJson(json);
}
