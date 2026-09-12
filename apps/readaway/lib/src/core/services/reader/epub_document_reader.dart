import 'dart:typed_data';

import 'package:mupdf/mupdf.dart';
import 'package:path/path.dart' as p;

import 'reflowable_document_reader.dart';

/// Compatibility alias for [ReflowableSectionItem].
typedef EpubSpineItem = ReflowableSectionItem;

/// Compatibility alias for [EpubDocumentReader].
typedef EpubSpineReader = EpubDocumentReader;

/// EPUB implementation of [ReflowableDocumentReader].
///
/// Backed natively by MuPDF's Fitz archive engine.
class EpubDocumentReader implements ReflowableDocumentReader {
  final MuPdfEpubSpine _nativeSpine;
  final List<ReflowableSectionItem> _sections;
  final Map<String, int> _sectionIndexByNormalizedHref;
  bool _disposed = false;

  EpubDocumentReader._(
    this._nativeSpine,
    this._sections,
    this._sectionIndexByNormalizedHref,
  );

  /// Opens an EPUB document from [filePath] using native MuPDF Fitz archive engine.
  static Future<EpubDocumentReader> fromFile(String filePath) async {
    final nativeSpine = MuPdfEpubSpine.openFile(filePath);
    final sections = nativeSpine.items
        .map(
          (item) => ReflowableSectionItem(
            index: item.index,
            id: item.id,
            href: item.path,
            mediaType: item.mediaType,
          ),
        )
        .toList();

    final sectionIndexByNormalizedHref = <String, int>{};
    for (final sec in sections) {
      final norm = p.posix.normalize(sec.href);
      sectionIndexByNormalizedHref[norm] = sec.index;
      sectionIndexByNormalizedHref[p.posix.basename(sec.href)] = sec.index;
    }

    return EpubDocumentReader._(
      nativeSpine,
      sections,
      sectionIndexByNormalizedHref,
    );
  }

  @override
  int get sectionCount => _sections.length;

  /// Total number of spine items (chapters) in the document.
  int get spineCount => sectionCount;

  @override
  List<ReflowableSectionItem> get sections => List.unmodifiable(_sections);

  /// Ordered list of spine items.
  List<ReflowableSectionItem> get spineItems => sections;

  @override
  String loadSectionHtml(int index) {
    if (_disposed) throw StateError('EpubDocumentReader is disposed');
    if (index < 0 || index >= _sections.length) {
      throw RangeError.range(index, 0, _sections.length - 1, 'index');
    }
    return _nativeSpine.readChapterXhtml(index);
  }

  /// Retrieves the raw XHTML string for the spine item at [index].
  String loadSpineHtml(int index) => loadSectionHtml(index);

  @override
  Uint8List? loadAssetBytes(String assetPath) {
    if (_disposed) throw StateError('EpubDocumentReader is disposed');
    final cleanPath = assetPath.startsWith('/')
        ? assetPath.substring(1)
        : assetPath;
    final stripped = cleanPath.split('?').first.split('#').first;
    final decoded = Uri.decodeComponent(stripped);

    var bytes = _nativeSpine.readAsset(cleanPath);
    if (bytes != null && bytes.isNotEmpty) return bytes;

    if (decoded != cleanPath) {
      bytes = _nativeSpine.readAsset(decoded);
      if (bytes != null && bytes.isNotEmpty) return bytes;
    }

    final normalized = p.posix.normalize(decoded);
    if (normalized != decoded) {
      bytes = _nativeSpine.readAsset(normalized);
      if (bytes != null && bytes.isNotEmpty) return bytes;
    }

    return null;
  }

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) {
    if (sectionIndex < 0 || sectionIndex >= _sections.length) {
      return relativeHref;
    }
    var cleanHref = relativeHref.split('?').first.split('#').first;
    cleanHref = Uri.decodeComponent(cleanHref);
    while (cleanHref.startsWith('/')) {
      cleanHref = cleanHref.substring(1);
    }

    final spineHref = _sections[sectionIndex].href;
    final spineDir = p.posix.dirname(spineHref);
    if (spineDir == '.' || spineDir.isEmpty) {
      return p.posix.normalize(cleanHref);
    }
    return p.posix.normalize(p.posix.join(spineDir, cleanHref));
  }

  @override
  int? resolveSectionIndex(String href) {
    if (href.isEmpty) return null;
    // Strip query parameters and anchors if any
    final cleanHref = href.split('#').first.split('?').first;
    if (cleanHref.isEmpty) return null;

    final norm = p.posix.normalize(cleanHref);
    if (_sectionIndexByNormalizedHref.containsKey(norm)) {
      return _sectionIndexByNormalizedHref[norm];
    }
    final base = p.posix.basename(cleanHref);
    return _sectionIndexByNormalizedHref[base];
  }

  @override
  void dispose() {
    if (!_disposed) {
      _nativeSpine.dispose();
      _disposed = true;
    }
  }
}
