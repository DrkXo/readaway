import '../models/models.dart';
import 'document_reader.dart';

/// A fixed-layout document (PDF, XPS) with discrete, non-reflowing pages.
///
/// Rendering and text extraction are expensive and should be offloaded to a
/// background isolate by callers; the interface is `Future`-based to make
/// that straightforward.
abstract class PdfDocumentReader implements DocumentReader {
  /// Total number of pages in the document.
  int get pageCount;

  /// Renders the page at [index] to raw RGBA pixels.
  Future<RenderedPage> renderPage(
    int index, {
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool alpha = false,
    int colorSpace = 0,
  });

  /// Extracts plain text from the page at [index].
  Future<String> extractText(int index);

  /// Extracts HTML from the page at [index], optionally embedding images.
  Future<String> extractHtml(int index, {bool preserveImages = false});

  /// Searches for [needle] on the page at [index], returning match quads.
  Future<List<SearchHit>> search(int index, String needle);

  /// Returns interactive links on the page at [index].
  Future<List<PageLink>> pageLinks(int index);

  /// Resolves an internal link [href] to a page number, if found.
  Future<int?> resolvePage(String href);
}
