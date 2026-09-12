import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../epub/epub_spine_reader.dart';
import 'reflowable_document_reader.dart';

/// EPUB implementation of [ReflowableDocumentReader].
///
/// Backed natively by MuPDF's Fitz archive engine with fast fallback to [package:archive].
class EpubDocumentReader implements ReflowableDocumentReader {
  final EpubSpineReader _spineReader;
  late final List<ReflowableSectionItem> _sections;
  late final Map<String, int> _sectionIndexByNormalizedHref;

  EpubDocumentReader._(this._spineReader) {
    _sections = _spineReader.spineItems
        .map(
          (item) => ReflowableSectionItem(
            index: item.index,
            id: item.id,
            href: item.href,
            mediaType: item.mediaType,
            title: item.title,
          ),
        )
        .toList();

    _sectionIndexByNormalizedHref = {};
    for (final sec in _sections) {
      final norm = p.posix.normalize(sec.href);
      _sectionIndexByNormalizedHref[norm] = sec.index;
      _sectionIndexByNormalizedHref[p.posix.basename(sec.href)] = sec.index;
    }
  }

  /// Opens an EPUB document from [filePath].
  static Future<EpubDocumentReader> fromFile(String filePath) async {
    final spineReader = await EpubSpineReader.fromFile(filePath);
    return EpubDocumentReader._(spineReader);
  }

  /// Opens an EPUB document from in-memory [bytes].
  static EpubDocumentReader fromBytes(List<int> bytes) {
    final spineReader = EpubSpineReader.fromBytes(bytes);
    return EpubDocumentReader._(spineReader);
  }

  @override
  int get sectionCount => _sections.length;

  @override
  List<ReflowableSectionItem> get sections => List.unmodifiable(_sections);

  @override
  String loadSectionHtml(int index) {
    return _spineReader.loadSpineHtml(index);
  }

  @override
  Uint8List? loadAssetBytes(String assetPath) {
    final bytes = _spineReader.loadAssetBytes(assetPath);
    if (bytes == null) return null;
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) {
    return _spineReader.resolveAssetPath(sectionIndex, relativeHref);
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
    _spineReader.dispose();
  }
}
