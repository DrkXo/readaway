part of '../models.dart';

/// Result of parsing an EPUB package document (OPF).
@freezed
abstract class OpfData with _$OpfData {
  const factory OpfData({
    /// Bibliographic metadata from `<metadata>`.
    required DocumentMetadata metadata,

    /// Ordered spine sections, with hrefs resolved relative to the OPF dir.
    required List<DocumentSection> sections,

    /// Manifest href of the NCX (EPUB 2), if present.
    String? ncxHref,

    /// Manifest href of the `<nav>` document (EPUB 3), if present.
    String? navHref,

    /// Directory containing the OPF, used to resolve relative paths.
    @Default('') String opfDir,

    /// Resolved path of the cover image asset, if the OPF declares one.
    String? coverImagePath,
  }) = _OpfData;

  factory OpfData.fromJson(Map<String, dynamic> json) =>
      _$OpfDataFromJson(json);
}
