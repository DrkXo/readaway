part of 'models.dart';

/// A single section/chapter in a reflowable document.
///
/// Sections are the atomic units of a reflowable document (e.g. one EPUB
/// spine item, or the single body of a standalone HTML/text file).
@freezed
abstract class DocumentSection with _$DocumentSection {
  const factory DocumentSection({
    /// Zero-based position in the document's section order.
    required int index,

    /// Stable identifier from the source manifest (e.g. EPUB `id`).
    required String id,

    /// Path/href of the section within the document container.
    required String href,

    /// MIME type of the section content (e.g. `application/xhtml+xml`).
    required String mediaType,

    /// Optional human-readable section title.
    String? title,
  }) = _DocumentSection;

  factory DocumentSection.fromJson(Map<String, dynamic> json) =>
      _$DocumentSectionFromJson(json);
}
