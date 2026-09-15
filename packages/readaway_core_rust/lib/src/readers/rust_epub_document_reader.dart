import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../abstracts/reflowable_document_reader.dart';
import '../errors/document_exception.dart';
import '../models/document_metadata.dart';
import '../models/document_section.dart';
import '../models/outline_item.dart';
import '../rust/api/document.dart' as doc_api;
import '../rust/rust_init.dart';

/// High-performance reflowable EPUB document reader backed by `rbook` in Rust.
class RustEpubDocumentReader implements ReflowableDocumentReader {
  final String filePath;
  final DocumentMetadata _metadata;
  final List<OutlineItem> _outline;
  final List<DocumentSection> _sections;
  final List<String> _spineHrefs;
  final Map<int, String> _sectionHtmlCache = {};
  final Map<String, Uint8List?> _assetCache = {};
  bool _disposed = false;

  RustEpubDocumentReader._({
    required this.filePath,
    required this._metadata,
    required this._outline,
    required this._sections,
    required this._spineHrefs,
  });

  /// Opens an EPUB document from [filePath].
  static Future<RustEpubDocumentReader> open(String filePath) async {
    await ensureRustInitialized();
    final rawMeta = await doc_api.getEpubMetadata(path: filePath);

    final count = (await doc_api.getEpubSectionCount(path: filePath)).toInt();
    final spineHrefs = await doc_api.getEpubSpineHrefs(path: filePath);
    final rawToc = await doc_api.getEpubToc(path: filePath);

    final metadata = DocumentMetadata(
      title: rawMeta.title,
      author: rawMeta.author,
      language: rawMeta.language,
      identifier: rawMeta.identifier,
      publisher: rawMeta.publisher,
      description: rawMeta.description,
      coverImagePath: rawMeta.coverImagePath,
    );

    final outline = rawToc.map(OutlineItem.fromRust).toList();

    final sections = List.generate(count, (i) {
      final href = i < spineHrefs.length ? spineHrefs[i] : 'section_$i.xhtml';
      return DocumentSection(
        id: 'section_$i',
        index: i,
        href: href,
        title: null,
      );
    });

    return RustEpubDocumentReader._(
      filePath: filePath,
      metadata: metadata,
      outline: outline,
      sections: sections,
      spineHrefs: spineHrefs,
    );
  }

  @override
  String get format => 'epub';

  @override
  bool get isReflowable => true;

  @override
  String? get title => _metadata.title;

  @override
  DocumentMetadata? get metadata => _metadata;

  @override
  List<OutlineItem> get outline => _outline;

  @override
  String? get coverImagePath => _metadata.coverImagePath;

  @override
  int get sectionCount => _sections.length;

  @override
  List<DocumentSection> get sections => _sections;

  @override
  String loadSectionHtml(int index) {
    if (_disposed) {
      throw DocumentDisposedException('RustEpubDocumentReader has been disposed');
    }
    if (index < 0 || index >= sectionCount) {
      throw RangeError.index(index, _sections);
    }

    final cached = _sectionHtmlCache[index];
    if (cached != null) return cached;

    try {
      final html = doc_api.readEpubSectionSync(
        path: filePath,
        sectionIndex: BigInt.from(index),
      );
      _sectionHtmlCache[index] = html;
      return html;
    } catch (e) {
      throw DocumentParseException('Failed to read section $index: $e');
    }
  }

  /// Preloads a section's HTML content asynchronously.
  Future<String> preloadSectionHtml(int index) async {
    if (_disposed) {
      throw DocumentDisposedException('RustEpubDocumentReader has been disposed');
    }
    if (index < 0 || index >= sectionCount) {
      throw RangeError.index(index, _sections);
    }

    final cached = _sectionHtmlCache[index];
    if (cached != null) return cached;

    final html = await doc_api.readEpubSection(
      path: filePath,
      sectionIndex: BigInt.from(index),
    );
    _sectionHtmlCache[index] = html;
    return html;
  }

  @override
  Uint8List? loadAsset(String assetPath) {
    if (_disposed) return null;
    final cached = _assetCache[assetPath];
    if (cached != null) return cached;

    try {
      final bytes = doc_api.readEpubResourceSync(
        path: filePath,
        resourcePath: assetPath,
      );
      _assetCache[assetPath] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Preloads an embedded resource asynchronously into the asset cache.
  Future<Uint8List?> preloadAsset(String assetPath) async {
    if (_disposed) return null;
    if (_assetCache.containsKey(assetPath)) return _assetCache[assetPath];

    try {
      final bytes = await doc_api.readEpubResource(
        path: filePath,
        resourcePath: assetPath,
      );
      _assetCache[assetPath] = bytes;
      return bytes;
    } catch (_) {
      _assetCache[assetPath] = null;
      return null;
    }
  }

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) {
    if (relativeHref.startsWith('/') || relativeHref.contains('://')) {
      return relativeHref;
    }
    if (sectionIndex < 0 || sectionIndex >= _spineHrefs.length) {
      return relativeHref;
    }

    final sectionHref = _spineHrefs[sectionIndex];
    final sectionDir = p.posix.dirname(sectionHref);
    return p.posix.normalize(p.posix.join(sectionDir, relativeHref));
  }

  @override
  int? resolveSectionIndex(String href) {
    final clean = href.split('#').first.trim().replaceAll(r'^\/+', '');
    final idx = _spineHrefs.indexWhere(
      (s) => s == clean || p.posix.basename(s) == p.posix.basename(clean),
    );
    return idx != -1 ? idx : null;
  }

  @override
  void dispose() {
    _disposed = true;
    _sectionHtmlCache.clear();
    _assetCache.clear();
  }
}

/// Compatibility typedef for drop-in replacement of readaway_core's EpubDocumentReader.
typedef EpubDocumentReader = RustEpubDocumentReader;

