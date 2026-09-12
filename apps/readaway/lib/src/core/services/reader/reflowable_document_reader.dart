import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'epub_document_reader.dart';
import 'plain_text_document_reader.dart';
import 'single_html_document_reader.dart';

/// Represents a single section or chapter in a reflowable document.
class ReflowableSectionItem {
  final int index;
  final String id;
  final String href;
  final String mediaType;
  final String? title;

  const ReflowableSectionItem({
    required this.index,
    required this.id,
    required this.href,
    required this.mediaType,
    this.title,
  });

  @override
  String toString() =>
      'ReflowableSectionItem(index: $index, id: $id, href: $href)';
}

/// Universal interface for reflowable e-book and document formats.
///
/// Reflowable documents (EPUB, Single HTML, Plain Text) are rendered
/// exclusively by HyperRender directly from semantic HTML/XHTML source.
abstract class ReflowableDocumentReader {
  /// Total number of sections/chapters in the document.
  int get sectionCount;

  /// Ordered list of document sections.
  List<ReflowableSectionItem> get sections;

  /// Retrieves the raw XHTML/HTML content for section at [index].
  String loadSectionHtml(int index);

  /// Retrieves raw binary content for an embedded asset (e.g. image, font) at [assetPath].
  Uint8List? loadAssetBytes(String assetPath);

  /// Resolves an asset path relative to the section at [sectionIndex].
  String resolveAssetPath(int sectionIndex, String relativeHref);

  /// Resolves an internal link target [href] to a section index, if found.
  int? resolveSectionIndex(String href);

  /// Releases any native C or file handles.
  void dispose();

  /// Opens a reflowable document from [filePath], auto-detecting the format.
  static Future<ReflowableDocumentReader> fromFile(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.epub':
        return EpubDocumentReader.fromFile(filePath);
      case '.html':
      case '.htm':
      case '.xhtml':
        return SingleHtmlDocumentReader.fromFile(filePath);
      case '.txt':
        return PlainTextDocumentReader.fromFile(filePath);
      default:
        return EpubDocumentReader.fromFile(filePath);
    }
  }
}
