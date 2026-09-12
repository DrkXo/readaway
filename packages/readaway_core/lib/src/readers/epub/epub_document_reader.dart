import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../abstracts/reflowable_document_reader.dart';
import '../../errors/document_exception.dart';
import '../../models/models.dart';
import 'epub_container.dart';
import 'nav_parser.dart';
import 'ncx_parser.dart';
import 'opf_parser.dart';

/// Pure-Dart EPUB implementation of [ReflowableDocumentReader].
///
/// Parses the EPUB ZIP container, OPF package document, and NCX/`<nav>`
/// outline entirely in Dart — no native dependencies.
class EpubDocumentReader implements ReflowableDocumentReader {
  /// Maximum number of asset entries kept in the in-memory cache.
  static const int _maxCachedAssets = 256;

  final EpubContainer _container;
  final List<DocumentSection> _sections;
  final Map<String, int> _sectionIndexByNormalizedHref;
  final DocumentMetadata? _metadata;
  final List<OutlineItem> _outline;
  final String? _coverImagePath;
  final Map<String, Uint8List> _assetCache = {};
  bool _disposed = false;

  EpubDocumentReader._({
    required this._container,
    required this._sections,
    required this._sectionIndexByNormalizedHref,
    required this._metadata,
    required this._outline,
    required this._coverImagePath,
  });

  /// Opens an EPUB document from [filePath].
  static Future<EpubDocumentReader> fromFile(String filePath) async {
    final container = EpubContainer.openFile(filePath);
    try {
      return await _open(container);
    } catch (_) {
      container.dispose();
      rethrow;
    }
  }

  /// Opens an EPUB document from raw [bytes].
  static Future<EpubDocumentReader> fromBytes(Uint8List bytes) async {
    final container = EpubContainer.openBytes(bytes);
    try {
      return await _open(container);
    } catch (_) {
      container.dispose();
      rethrow;
    }
  }

  /// Opens the reader, offloading the expensive XML parsing to a background
  /// isolate while keeping the lazy ZIP container on the main isolate.
  static Future<EpubDocumentReader> _open(EpubContainer container) async {
    final opfParser = const OpfParser();

    // 1. Locate the OPF (tiny container.xml — cheap on the main isolate).
    final opfPath =
        opfParser.findOpfPath(container) ??
        opfParser.findFallbackOpf(container);
    if (opfPath == null) {
      throw DocumentParseException('No OPF package document found in EPUB');
    }
    final opfBytes = container.readEntry(opfPath);
    if (opfBytes == null || opfBytes.isEmpty) {
      throw DocumentParseException('OPF package document is empty: $opfPath');
    }
    final opfDir = opfPath.contains('/') ? p.posix.dirname(opfPath) : '';

    // 2. Parse the OPF in a background isolate (dominant cost).
    final opf = await Isolate.run(
      () => opfParser.parseBytes(opfBytes, opfDir: opfDir),
    );

    // 3. Read the NCX/nav bytes on the main isolate (fast).
    final ncxPath = _resolveContainerPath(opf.opfDir, opf.ncxHref);
    final ncxBytes = ncxPath != null ? container.readEntry(ncxPath) : null;
    final navPath = _resolveContainerPath(opf.opfDir, opf.navHref);
    final navBytes = navPath != null ? container.readEntry(navPath) : null;

    // 4. Parse the outline in a background isolate.
    final outline = await Isolate.run(
      () =>
          _parseOutlineBytes(opf: opf, ncxBytes: ncxBytes, navBytes: navBytes),
    );

    // 5. Build the section index map.
    final sections = opf.sections;
    final sectionIndexByNormalizedHref = <String, int>{};
    for (final sec in sections) {
      final norm = p.posix.normalize(sec.href);
      sectionIndexByNormalizedHref[norm] = sec.index;
      sectionIndexByNormalizedHref[p.posix.basename(sec.href)] = sec.index;
    }

    return EpubDocumentReader._(
      container: container,
      sections: sections,
      sectionIndexByNormalizedHref: sectionIndexByNormalizedHref,
      metadata: opf.metadata,
      outline: outline,
      coverImagePath: opf.coverImagePath,
    );
  }

  /// Parses the outline from raw NCX/nav bytes. Runs in a background isolate.
  static List<OutlineItem> _parseOutlineBytes({
    required OpfData opf,
    required Uint8List? ncxBytes,
    required Uint8List? navBytes,
  }) {
    String? resolveHref(String src) {
      if (src.isEmpty) return src;
      final clean = src.split('#').first;
      if (opf.opfDir.isNotEmpty &&
          !clean.startsWith('/') &&
          !clean.contains('/')) {
        return p.posix.normalize(p.posix.join(opf.opfDir, clean));
      }
      return clean;
    }

    final sectionIndexByHref = <String, int>{};
    for (final sec in opf.sections) {
      sectionIndexByHref[p.posix.normalize(sec.href)] = sec.index;
      sectionIndexByHref[p.posix.basename(sec.href)] = sec.index;
    }
    int? resolveSectionIndex(String href) {
      final clean = href.split('#').first.split('?').first;
      if (clean.isEmpty) return null;
      final norm = p.posix.normalize(clean);
      return sectionIndexByHref[norm] ??
          sectionIndexByHref[p.posix.basename(norm)];
    }

    // 1. Try NCX (EPUB 2).
    if (ncxBytes != null && ncxBytes.isNotEmpty) {
      try {
        final outline = const NcxParser().parse(
          ncxBytes,
          resolveHref: resolveHref,
          resolveSectionIndex: resolveSectionIndex,
        );
        if (outline.isNotEmpty) return outline;
      } catch (_) {
        // Fall through to the next strategy.
      }
    }

    // 2. Try EPUB 3 `<nav>`.
    if (navBytes != null && navBytes.isNotEmpty) {
      try {
        final outline = const NavParser().parse(
          navBytes,
          resolveHref: resolveHref,
          resolveSectionIndex: resolveSectionIndex,
        );
        if (outline.isNotEmpty) return outline;
      } catch (_) {
        // Fall through to the flat fallback.
      }
    }

    // 3. Fallback: flat per-section outline.
    return [
      for (final sec in opf.sections)
        OutlineItem(
          title: sec.title ?? 'Chapter ${sec.index + 1}',
          href: sec.href,
          level: 0,
          chapterIndex: sec.index,
        ),
    ];
  }

  static String? _resolveContainerPath(String opfDir, String? href) {
    if (href == null || href.isEmpty) return null;
    if (opfDir.isNotEmpty && !href.startsWith('/')) {
      return p.posix.normalize(p.posix.join(opfDir, href));
    }
    return href;
  }

  @override
  String get format => 'epub';

  @override
  bool get isReflowable => true;

  @override
  String? get title => _metadata?.title;

  @override
  DocumentMetadata? get metadata => _metadata;

  @override
  List<OutlineItem> get outline => _outline;

  @override
  String? get coverImagePath => _coverImagePath;

  @override
  int get sectionCount => _sections.length;

  @override
  List<DocumentSection> get sections => _sections;

  @override
  String loadSectionHtml(int index) {
    _checkNotDisposed();
    if (index < 0 || index >= _sections.length) {
      throw RangeError.index(
        index,
        _sections,
        'index',
        'section index out of range',
      );
    }
    final href = _sections[index].href;
    final bytes = _container.readEntry(href);
    if (bytes == null || bytes.isEmpty) {
      throw DocumentParseException('Section content missing: $href');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  @override
  Uint8List? loadAsset(String assetPath) {
    _checkNotDisposed();
    final cached = _assetCache[assetPath];
    if (cached != null) return cached;
    final bytes = _container.readEntry(assetPath);
    if (bytes != null) {
      _cacheAsset(assetPath, bytes);
    }
    return bytes;
  }

  void _cacheAsset(String path, Uint8List bytes) {
    if (_assetCache.length >= _maxCachedAssets) {
      // Evict the least-recently-inserted entry.
      final oldest = _assetCache.keys.first;
      _assetCache.remove(oldest);
    }
    _assetCache[path] = bytes;
  }

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) {
    if (sectionIndex < 0 || sectionIndex >= _sections.length) {
      return relativeHref;
    }
    final sectionHref = _sections[sectionIndex].href;
    final baseDir = p.posix.dirname(sectionHref);
    if (relativeHref.startsWith('/')) {
      return p.posix.normalize(relativeHref.substring(1));
    }
    if (baseDir.isEmpty) {
      return p.posix.normalize(relativeHref);
    }
    return p.posix.normalize(p.posix.join(baseDir, relativeHref));
  }

  @override
  int? resolveSectionIndex(String href) {
    _checkNotDisposed();
    if (href.isEmpty) return null;
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
    if (_disposed) return;
    _disposed = true;
    _assetCache.clear();
    _container.dispose();
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw DocumentDisposedException('EpubDocumentReader has been disposed');
    }
  }
}
