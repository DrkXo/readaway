part of 'models.dart';

/// An interactive link on a fixed-layout page.
@freezed
abstract class PageLink with _$PageLink {
  const factory PageLink({
    /// Clickable region in page coordinates.
    required PageRect bounds,

    /// External URI, if this is an external link.
    String? uri,

    /// Resolved target page, if this is an internal link.
    int? pageNumber,
  }) = _PageLink;

  const PageLink._();

  /// Whether this link points to another page within the document.
  bool get isInternal => pageNumber != null;
}
