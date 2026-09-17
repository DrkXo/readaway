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

  final Map<int, String> _sectionHtmlCache = {};
  final Map<String, Uint8List?> _assetCache = {};

  EpubDocumentReader._({
    required this.filePath,
    required this._metadata,
    required List<OutlineItem> outline,
    required List<DocumentSection> sections,
    required List<String> spineHrefs,
    required this._archive,
    required this._entriesByName,
    required this._opfDir,
  }) : _outline = List.unmodifiable(outline),
       _sections = List.unmodifiable(sections),
       _spineHrefs = List.unmodifiable(spineHrefs);

  /// Opens an EPUB document from [filePath].
  static Future<EpubDocumentReader> open(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('EPUB file not found: $filePath');
    }
    final bytes = file.readAsBytesSync();
    return fromBytes(bytes, filePath: filePath);
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
      containerFile.content as List<int>,
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
      opfFile.content as List<int>,
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
            ncxFile.content as List<int>,
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
      final html = utf8.decode(file.content as List<int>, allowMalformed: true);
      _sectionHtmlCache[index] = html;
      return html;
    } catch (e) {
      throw DocumentParseException('Failed to read section $index: $e');
    }
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

    final bytes = Uint8List.fromList(file.content as List<int>);
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
    _entriesByName.clear();
  }

  ArchiveFile? _findFile(String path) {
    final norm = _normalizePath(path);
    var file = _entriesByName[norm] ?? _entriesByName[path];
    if (file != null) return file;

    // Try relative to opfDir
    if (_opfDir.isNotEmpty && !norm.startsWith('$_opfDir/')) {
      final withOpf = _normalizePath('$_opfDir/$norm');
      file = _entriesByName[withOpf];
      if (file != null) return file;
    }

    // Try finding by basename as last resort
    final base = p.posix.basename(norm);
    for (final entry in _archive) {
      if (entry.isFile && p.posix.basename(entry.name) == base) {
        return entry;
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

          int? chapterIndex;
          if (resolvedHref != null) {
            final cleanHref = resolvedHref.split('#').first;
            chapterIndex = spineHrefs.indexWhere(
              (s) =>
                  _normalizePath(s) == _normalizePath(cleanHref) ||
                  p.posix.basename(s) == p.posix.basename(cleanHref),
            );
            if (chapterIndex == -1) chapterIndex = null;
          }

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

          int? chapterIndex;
          if (resolvedHref != null) {
            final cleanHref = resolvedHref.split('#').first;
            chapterIndex = spineHrefs.indexWhere(
              (s) =>
                  _normalizePath(s) == _normalizePath(cleanHref) ||
                  p.posix.basename(s) == p.posix.basename(cleanHref),
            );
            if (chapterIndex == -1) chapterIndex = null;
          }

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
}
