import '../models/models.dart';
import 'document_reader.dart';

/// A document whose content reflows to fit the viewport (EPUB, HTML, text).
///
/// Reflowable documents are organized into ordered [sections] (chapters /
/// spine items). Each section's content is exposed as semantic HTML/XHTML
/// via [loadSectionHtml], ready for a rendering engine.
abstract class ReflowableDocumentReader implements DocumentReader {
  /// Total number of sections/chapters in the document.
  int get sectionCount;

  /// Ordered list of document sections.
  List<DocumentSection> get sections;

  /// Retrieves the raw XHTML/HTML content for the section at [index].
  String loadSectionHtml(int index);

  /// Resolves an asset path relative to the section at [sectionIndex].
  String resolveAssetPath(int sectionIndex, String relativeHref);

  /// Resolves an internal link target [href] to a section index, if found.
  int? resolveSectionIndex(String href);
}
