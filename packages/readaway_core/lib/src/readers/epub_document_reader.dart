import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../abstracts/reflowable_document_reader.dart';
import '../errors/document_exception.dart';
import '../lifecycle/disposable.dart';
import '../models/models.dart';

/// High-performance reflowable EPUB document reader implemented in pure Dart.
class EpubDocumentReader
    with DisposableMixin
    implements ReflowableDocumentReader {
  final String filePath;
  final DocumentMetadata _metadata;
  final List<OutlineItem> _outline;
  final List<DocumentSection> _sections;
  final List<String> _spineHrefs;
  final Archive _archive;
  final Map<String, ArchiveFile> _entriesByName;
  final String _opfDir;
  final InputFileStream? _inputStream;

  final Map<int, String> _sectionHtmlCache = {};
  final Map<String, Uint8List?> _assetCache = {};
  final Map<String, String> _cssCache = {};

  EpubDocumentReader._({
    required this.filePath,
    required this._metadata,
    required List<OutlineItem> outline,
    required List<DocumentSection> sections,
    required List<String> spineHrefs,
    required this._archive,
    required this._entriesByName,
    required this._opfDir,
    this._inputStream,
  }) : _outline = List.unmodifiable(outline),
       _sections = List.unmodifiable(sections),
       _spineHrefs = List.unmodifiable(spineHrefs);

  /// Opens an EPUB document from [filePath].
  static Future<EpubDocumentReader> open(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('EPUB file not found: $filePath');
    }
    final stream = InputFileStream(filePath);
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(stream, verify: false);
    } catch (e) {
      await stream.close();
      throw DocumentParseException('Failed to parse EPUB zip archive: $e');
    }
    return _fromArchive(
      archive,
      filePath: filePath,
      inputStream: stream,
    );
  }

  /// Opens an EPUB document from in-memory [bytes].
  static Future<EpubDocumentReader> fromBytes(
    Uint8List bytes, {
    String filePath = 'document.epub',
  }) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (e) {
      throw DocumentParseException('Failed to parse EPUB zip archive: $e');
    }
    return _fromArchive(archive, filePath: filePath);
  }

  static Future<EpubDocumentReader> _fromArchive(
    Archive archive, {
    required String filePath,
    InputFileStream? inputStream,
  }) async {

    final entriesByName = <String, ArchiveFile>{};
    for (final file in archive) {
      if (file.isFile) {
        entriesByName[file.name] = file;
        entriesByName[_normalizePath(file.name)] = file;
      }
    }

    // 1. Locate root OPF file from META-INF/container.xml
    final containerFile =
        entriesByName['META-INF/container.xml'] ??
        entriesByName['meta-inf/container.xml'];
    if (containerFile == null) {
      throw const DocumentParseException(
        'Missing META-INF/container.xml in EPUB',
      );
    }

    final containerXmlStr = utf8.decode(
      _extractBytes(containerFile),
      allowMalformed: true,
    );
    final containerXml = XmlDocument.parse(containerXmlStr);
    final rootfileElem = containerXml.findAllElements('rootfile').firstOrNull;
    final opfFullPath = rootfileElem?.getAttribute('full-path');
    if (opfFullPath == null || opfFullPath.isEmpty) {
      throw const DocumentParseException(
        'Could not determine OPF full-path from container.xml',
      );
    }

    final normalizedOpfPath = _normalizePath(opfFullPath);
    final opfFile =
        entriesByName[normalizedOpfPath] ?? entriesByName[opfFullPath];
    if (opfFile == null) {
      throw DocumentParseException('Package OPF file not found: $opfFullPath');
    }

    final opfDir = p.posix.dirname(normalizedOpfPath);
    final opfXmlStr = utf8.decode(
      _extractBytes(opfFile),
      allowMalformed: true,
    );
    final opfXml = XmlDocument.parse(opfXmlStr);

    // 2. Parse Metadata
    final metadataElem = opfXml.findAllElements('metadata').firstOrNull;
    final title = metadataElem
        ?.findElements('dc:title')
        .firstOrNull
        ?.innerText
        .trim();
    final creator =
        metadataElem
            ?.findElements('dc:creator')
            .firstOrNull
            ?.innerText
            .trim() ??
        metadataElem?.findElements('dc:author').firstOrNull?.innerText.trim();
    final language = metadataElem
        ?.findElements('dc:language')
        .firstOrNull
        ?.innerText
        .trim();
    final identifier = metadataElem
        ?.findElements('dc:identifier')
        .firstOrNull
        ?.innerText
        .trim();
    final publisher = metadataElem
        ?.findElements('dc:publisher')
        .firstOrNull
        ?.innerText
        .trim();
    final description = metadataElem
        ?.findElements('dc:description')
        .firstOrNull
        ?.innerText
        .trim();

    // 3. Parse Manifest
    final manifestItems =
        <String, ({String href, String mediaType, String? properties})>{};
    final manifestElem = opfXml.findAllElements('manifest').firstOrNull;
    String? coverImageHref;
    String? coverMetaId;

    if (metadataElem != null) {
      for (final meta in metadataElem.findElements('meta')) {
        if (meta.getAttribute('name')?.toLowerCase() == 'cover') {
          coverMetaId = meta.getAttribute('content');
          break;
        }
      }
    }

    String? ncxHref;
    String? navHref;

    if (manifestElem != null) {
      for (final item in manifestElem.findElements('item')) {
        final id = item.getAttribute('id');
        final href = item.getAttribute('href');
        final mediaType = item.getAttribute('media-type') ?? '';
        final properties = item.getAttribute('properties');

        if (id != null && href != null) {
          final decodedHref = Uri.decodeComponent(href);
          manifestItems[id] = (
            href: decodedHref,
            mediaType: mediaType,
            properties: properties,
          );

          if (id == coverMetaId ||
              properties?.contains('cover-image') == true) {
            coverImageHref = decodedHref;
          } else if (coverImageHref == null &&
              (id.toLowerCase().contains('cover') &&
                  mediaType.startsWith('image/'))) {
            coverImageHref = decodedHref;
          }

          if (mediaType == 'application/x-dtbncx+xml' ||
              id.toLowerCase() == 'ncx') {
            ncxHref = decodedHref;
          }
          if (properties?.contains('nav') == true) {
            navHref = decodedHref;
          }
        }
      }
    }

    String? resolvedCoverPath;
    if (coverImageHref != null) {
      resolvedCoverPath = _resolveRelative(opfDir, coverImageHref);
    }

    final metadata = DocumentMetadata.normalized(
      title: title,
      author: creator,
      creator: creator,
      language: language,
      identifier: identifier,
      publisher: publisher,
      description: description,
      coverImagePath: resolvedCoverPath,
    );

    // 4. Parse Spine
    final spineElem = opfXml.findAllElements('spine').firstOrNull;
    final spineHrefs = <String>[];
    final sections = <DocumentSection>[];

    if (spineElem != null) {
      var sectionIdx = 0;
      for (final itemref in spineElem.findElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        if (idref != null && manifestItems.containsKey(idref)) {
          final item = manifestItems[idref]!;
          final fullHref = _resolveRelative(opfDir, item.href);
          spineHrefs.add(fullHref);
          sections.add(
            DocumentSection(
              id: idref,
              index: sectionIdx,
              href: fullHref,
              title: null,
            ),
          );
          sectionIdx++;
        }
      }
    }

    // 5. Parse Table of Contents (Outline)
    List<OutlineItem> outline = const [];
    if (navHref != null) {
      final navFullPath = _resolveRelative(opfDir, navHref);
      final navFile =
          entriesByName[navFullPath] ??
          entriesByName[_normalizePath(navFullPath)];
      if (navFile != null) {
        try {
          final navXmlStr = utf8.decode(
            navFile.content as List<int>,
            allowMalformed: true,
          );
          outline = _parseNavDocument(
            navXmlStr,
            p.posix.dirname(navFullPath),
            spineHrefs,
          );
        } catch (_) {}
      }
    }

    if (outline.isEmpty && ncxHref != null) {
      final ncxFullPath = _resolveRelative(opfDir, ncxHref);
      final ncxFile =
          entriesByName[ncxFullPath] ??
          entriesByName[_normalizePath(ncxFullPath)];
      if (ncxFile != null) {
        try {
          final ncxXmlStr = utf8.decode(
            _extractBytes(ncxFile),
            allowMalformed: true,
          );
          outline = _parseNcxDocument(
            ncxXmlStr,
            p.posix.dirname(ncxFullPath),
            spineHrefs,
          );
        } catch (_) {}
      }
    }

    return EpubDocumentReader._(
      filePath: filePath,
      metadata: metadata,
      outline: outline,
      sections: sections,
      spineHrefs: spineHrefs,
      archive: archive,
      entriesByName: entriesByName,
      opfDir: opfDir,
      inputStream: inputStream,
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
    checkNotDisposed('loadSectionHtml');
    if (index < 0 || index >= sectionCount) {
      throw RangeError.index(index, _sections);
    }

    final cached = _sectionHtmlCache[index];
    if (cached != null) return cached;

    final href = _spineHrefs[index];
    final file = _findFile(href);
    if (file == null) {
      throw DocumentParseException('Section file not found in EPUB: $href');
    }

    try {
      final rawHtml = utf8.decode(_extractBytes(file), allowMalformed: true);
      final html = _inlineStylesheets(rawHtml, href);
      _sectionHtmlCache[index] = html;
      return html;
    } catch (e) {
      throw DocumentParseException('Failed to read section $index: $e');
    }
  }

  /// Inlines external stylesheets referenced via `<link>` tags directly into
  /// `<style>` blocks so downstream renderers receive fully-styled documents.
  String _inlineStylesheets(String html, String sectionHref) {
    if (!html.contains('<link')) return html;

    final sectionDir = p.posix.dirname(sectionHref);
    final linkRegex = RegExp(
      r'<link\b([^>]*?)(?:\/?>|\/>)',
      caseSensitive: false,
    );

    return html.replaceAllMapped(linkRegex, (match) {
      final attrs = match.group(1) ?? '';
      final isStylesheet = attrs.contains(
            RegExp(r'rel\s*=\s*["\x27]?stylesheet["\x27]?', caseSensitive: false),
          ) ||
          attrs.contains(
            RegExp(r'type\s*=\s*["\x27]?text/css["\x27]?', caseSensitive: false),
          );

      if (!isStylesheet) return match.group(0)!;

      final hrefMatch = RegExp(
        r'href\s*=\s*["\x27]([^"\x27]+)["\x27]',
        caseSensitive: false,
      ).firstMatch(attrs);
      if (hrefMatch == null) return match.group(0)!;

      final rawHref = hrefMatch.group(1)!.trim();
      final href = Uri.decodeComponent(rawHref);
      if (href.isEmpty) return match.group(0)!;

      final resolvedPath = _resolveRelative(sectionDir, href);
      final cssContent = _loadCssContent(resolvedPath);
      if (cssContent == null || cssContent.trim().isEmpty) {
        return match.group(0)!;
      }

      return '<style type="text/css" data-href="$href">\n$cssContent\n</style>';
    });
  }

  /// Loads and caches CSS content by resolved path, expanding any `@import` rules.
  String? _loadCssContent(String cssPath) {
    final cached = _cssCache[cssPath];
    if (cached != null) return cached;

    final file = _findFile(cssPath);
    if (file == null) return null;

    var content = utf8.decode(_extractBytes(file), allowMalformed: true);
    content = _resolveCssImports(content, p.posix.dirname(cssPath));
    _cssCache[cssPath] = content;
    return content;
  }

  /// Recursively inlines `@import` rules inside CSS content.
  String _resolveCssImports(String css, String cssDir) {
    final importRegex = RegExp(
      r'''@import\s+(?:url\(['"\x27]?([^'")\x27]+)['"\x27]?\)|['"\x27]([^'"\x27]+)['"\x27]);?''',
      caseSensitive: false,
    );

    return css.replaceAllMapped(importRegex, (match) {
      final importHref = match.group(1) ?? match.group(2);
      if (importHref == null || importHref.trim().isEmpty) return match.group(0)!;

      final cleanHref = Uri.decodeComponent(importHref.trim());
      final resolvedImportPath = _resolveRelative(cssDir, cleanHref);
      final importedContent = _loadCssContent(resolvedImportPath);
      if (importedContent == null) return '';
      return importedContent;
    });
  }

  /// Preloads a section's HTML content asynchronously.
  Future<String> preloadSectionHtml(int index) async => loadSectionHtml(index);

  @override
  Uint8List? loadAsset(String assetPath) {
    if (isDisposed) return null;
    final cached = _assetCache[assetPath];
    if (cached != null) return cached;

    final file = _findFile(assetPath);
    if (file == null) return null;

    final bytes = _extractBytes(file);
    _assetCache[assetPath] = bytes;
    return bytes;
  }

  /// Preloads an embedded resource asynchronously into the asset cache.
  Future<Uint8List?> preloadAsset(String assetPath) async =>
      loadAsset(assetPath);

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) {
    if (relativeHref.startsWith('/') || relativeHref.contains('://')) {
      return _normalizePath(relativeHref);
    }
    if (sectionIndex < 0 || sectionIndex >= _spineHrefs.length) {
      return _normalizePath(relativeHref);
    }

    final sectionHref = _spineHrefs[sectionIndex];
    final sectionDir = p.posix.dirname(sectionHref);
    return _resolveRelative(sectionDir, relativeHref);
  }

  @override
  int? resolveSectionIndex(String href) {
    if (href.isEmpty) return null;
    final clean = href.split('#').first.split('?').first.trim();
    final normalizedClean = _normalizePath(clean);

    // 1. Exact match
    for (var i = 0; i < _spineHrefs.length; i++) {
      final spineNormalized = _normalizePath(_spineHrefs[i]);
      if (spineNormalized == normalizedClean || _spineHrefs[i] == clean) {
        return i;
      }
    }

    // 2. Basename match
    final cleanBase = p.posix.basename(normalizedClean);
    for (var i = 0; i < _spineHrefs.length; i++) {
      if (p.posix.basename(_spineHrefs[i]) == cleanBase) {
        return i;
      }
    }

    return null;
  }

  @override
  void dispose() {
    super.dispose();
    _sectionHtmlCache.clear();
    _assetCache.clear();
    _cssCache.clear();
    _entriesByName.clear();
    _inputStream?.close();
  }

  static Uint8List _extractBytes(ArchiveFile file) {
    return file.readBytes() ?? Uint8List(0);
  }

  ArchiveFile? _findFile(String path) {
    final norm = _normalizePath(path);
    var file = _entriesByName[norm] ?? _entriesByName[path];
    if (file != null) return file;

    // Try URL-decoded path if different
    try {
      final decodedNorm = Uri.decodeComponent(norm);
      if (decodedNorm != norm) {
        file = _entriesByName[decodedNorm] ??
            _entriesByName[Uri.decodeComponent(path)];
        if (file != null) return file;
      }
    } catch (_) {}

    // Try relative to opfDir
    if (_opfDir.isNotEmpty && !norm.startsWith('$_opfDir/')) {
      final withOpf = _normalizePath('$_opfDir/$norm');
      file = _entriesByName[withOpf];
      if (file != null) return file;
      try {
        final decodedWithOpf = Uri.decodeComponent(withOpf);
        if (decodedWithOpf != withOpf) {
          file = _entriesByName[decodedWithOpf];
          if (file != null) return file;
        }
      } catch (_) {}
    }

    // Try finding by basename as last resort
    final base = p.posix.basename(norm);
    String? decodedBase;
    try {
      decodedBase = Uri.decodeComponent(base);
    } catch (_) {}

    for (final entry in _archive) {
      if (entry.isFile) {
        final entryBase = p.posix.basename(entry.name);
        if (entryBase == base ||
            (decodedBase != null && entryBase == decodedBase)) {
          return entry;
        }
      }
    }
    return null;
  }

  static String _normalizePath(String path) {
    var pStr = path.replaceAll(r'\', '/').trim();
    while (pStr.startsWith('/')) {
      pStr = pStr.substring(1);
    }
    return p.posix.normalize(pStr);
  }

  static String _resolveRelative(String baseDir, String relativePath) {
    if (relativePath.startsWith('/')) {
      return _normalizePath(relativePath);
    }
    if (baseDir.isEmpty || baseDir == '.') {
      return _normalizePath(relativePath);
    }
    return _normalizePath(p.posix.join(baseDir, relativePath));
  }

  static List<OutlineItem> _parseNcxDocument(
    String xmlStr,
    String ncxDir,
    List<String> spineHrefs,
  ) {
    try {
      final doc = XmlDocument.parse(xmlStr);
      final navMap = doc.findAllElements('navMap').firstOrNull;
      if (navMap == null) return const [];

      final spineIndex = _buildSpineIndex(spineHrefs);

      List<OutlineItem> parsePoints(XmlElement parent, int level) {
        final items = <OutlineItem>[];
        for (final navPoint in parent.findElements('navPoint')) {
          final label =
              navPoint
                  .findElements('navLabel')
                  .firstOrNull
                  ?.findElements('text')
                  .firstOrNull
                  ?.innerText
                  .trim() ??
              '';
          final src =
              navPoint
                  .findElements('content')
                  .firstOrNull
                  ?.getAttribute('src') ??
              '';
          final resolvedHref = src.isNotEmpty
              ? _resolveRelative(ncxDir, src)
              : null;

          int? chapterIndex = (resolvedHref == null)
              ? null
              : _chapterIndexForHref(resolvedHref, spineIndex);

          final children = parsePoints(navPoint, level + 1);

          items.add(
            OutlineItem(
              title: label.isNotEmpty ? label : 'Chapter',
              href: resolvedHref,
              level: level,
              chapterIndex: chapterIndex,
              children: children,
            ),
          );
        }
        return items;
      }

      return parsePoints(navMap, 0);
    } catch (_) {
      return const [];
    }
  }

  static List<OutlineItem> _parseNavDocument(
    String xmlStr,
    String navDir,
    List<String> spineHrefs,
  ) {
    try {
      final doc = XmlDocument.parse(xmlStr);
      final tocNav = doc
          .findAllElements('nav')
          .firstWhere(
            (nav) =>
                nav.getAttribute('epub:type') == 'toc' ||
                nav.getAttribute('type') == 'toc',
            orElse: () => doc.findAllElements('nav').first,
          );

      final ol = tocNav.findElements('ol').firstOrNull;
      if (ol == null) return const [];

      final spineIndex = _buildSpineIndex(spineHrefs);

      List<OutlineItem> parseOl(XmlElement parentOl, int level) {
        final items = <OutlineItem>[];
        for (final li in parentOl.findElements('li')) {
          final a = li.findElements('a').firstOrNull;
          final title =
              a?.innerText.trim() ??
              li.findElements('span').firstOrNull?.innerText.trim() ??
              '';
          final href = a?.getAttribute('href');
          final resolvedHref = (href != null && href.isNotEmpty)
              ? _resolveRelative(navDir, href)
              : null;

          int? chapterIndex = (resolvedHref == null)
              ? null
              : _chapterIndexForHref(resolvedHref, spineIndex);

          final childOl = li.findElements('ol').firstOrNull;
          final children = childOl != null
              ? parseOl(childOl, level + 1)
              : const <OutlineItem>[];

          items.add(
            OutlineItem(
              title: title.isNotEmpty ? title : 'Chapter',
              href: resolvedHref,
              level: level,
              chapterIndex: chapterIndex,
              children: children,
            ),
          );
        }
        return items;
      }

      return parseOl(ol, 0);
    } catch (_) {
      return const [];
    }
  }

  /// Builds an O(1) lookup from normalized path / basename to spine index,
  /// replacing the previous O(n·m) `indexWhere` scan used per outline item.
  static Map<String, int> _buildSpineIndex(List<String> spineHrefs) {
    final index = <String, int>{};
    for (var i = 0; i < spineHrefs.length; i++) {
      final s = spineHrefs[i];
      index[_normalizePath(s)] = i;
      // First entry wins for basename, matching the old `indexWhere` scan.
      index.putIfAbsent(p.posix.basename(s), () => i);
    }
    return index;
  }

  /// Maps a resolved outline href to its spine index, preferring an exact
  /// normalized-path match and falling back to basename matching.
  static int? _chapterIndexForHref(String resolvedHref, Map<String, int> index) {
    final cleanHref = resolvedHref.split('#').first;
    return index[_normalizePath(cleanHref)] ??
        index[p.posix.basename(cleanHref)];
  }
}
