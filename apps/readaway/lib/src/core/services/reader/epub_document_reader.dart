import 'dart:convert';
import 'dart:typed_data';

import 'package:mupdf/mupdf.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'reflowable_document_reader.dart';

/// Compatibility alias for [ReflowableSectionItem].
typedef EpubSpineItem = ReflowableSectionItem;

/// Compatibility alias for [EpubDocumentReader].
typedef EpubSpineReader = EpubDocumentReader;

class _EpubMetaAndOutline {
  final String? title;
  final List<OutlineItem> outline;
  const _EpubMetaAndOutline({this.title, required this.outline});
}

/// EPUB implementation of [ReflowableDocumentReader].
///
/// Backed natively by MuPDF's Fitz archive engine.
class EpubDocumentReader implements ReflowableDocumentReader {
  final MuPdfEpubSpine _nativeSpine;
  final List<ReflowableSectionItem> _sections;
  final Map<String, int> _sectionIndexByNormalizedHref;
  final String? _title;
  final List<OutlineItem> _outline;
  final Map<String, Uint8List> _assetCache = {};
  bool _disposed = false;

  EpubDocumentReader._(
    this._nativeSpine,
    this._sections,
    this._sectionIndexByNormalizedHref,
    this._title,
    this._outline,
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

    int? resolveIndex(String href) {
      if (href.isEmpty) return null;
      final cleanHref = href.split('#').first.split('?').first;
      if (cleanHref.isEmpty) return null;
      final norm = p.posix.normalize(cleanHref);
      if (sectionIndexByNormalizedHref.containsKey(norm)) {
        return sectionIndexByNormalizedHref[norm];
      }
      final base = p.posix.basename(cleanHref);
      return sectionIndexByNormalizedHref[base];
    }

    final meta = _parseMetadataAndOutline(nativeSpine, sections, resolveIndex);

    return EpubDocumentReader._(
      nativeSpine,
      sections,
      sectionIndexByNormalizedHref,
      meta.title,
      meta.outline,
    );
  }

  static _EpubMetaAndOutline _parseMetadataAndOutline(
    MuPdfEpubSpine spine,
    List<ReflowableSectionItem> sections,
    int? Function(String) resolveSectionIndex,
  ) {
    String? title;
    final outline = <OutlineItem>[];

    try {
      String? opfPath;
      final containerBytes = spine.readAsset('META-INF/container.xml');
      if (containerBytes != null && containerBytes.isNotEmpty) {
        try {
          final xmlDoc = XmlDocument.parse(
            utf8.decode(containerBytes, allowMalformed: true),
          );
          final rootfile = xmlDoc.findAllElements('rootfile').firstOrNull;
          opfPath = rootfile?.getAttribute('full-path');
        } catch (_) {}
      }

      Uint8List? opfBytes;
      if (opfPath != null && opfPath.isNotEmpty) {
        opfBytes = spine.readAsset(opfPath);
      }
      opfBytes ??=
          spine.readAsset('content.opf') ?? spine.readAsset('book.opf');

      String? ncxHref;
      String? navHref;
      String opfDir = '';
      if (opfPath != null && opfPath.contains('/')) {
        opfDir = p.posix.dirname(opfPath);
      }

      if (opfBytes != null && opfBytes.isNotEmpty) {
        try {
          final opfDoc = XmlDocument.parse(
            utf8.decode(opfBytes, allowMalformed: true),
          );
          final titleElem = opfDoc.findAllElements('dc:title').firstOrNull;
          final rawTitle = titleElem?.innerText.trim();
          if (rawTitle != null && rawTitle.isNotEmpty) {
            title = rawTitle;
          }

          // Check manifest for ncx or nav
          for (final item in opfDoc.findAllElements('item')) {
            final mediaType = item.getAttribute('media-type');
            final properties = item.getAttribute('properties');
            final href = item.getAttribute('href');
            if (href == null || href.isEmpty) continue;

            if (mediaType == 'application/x-dtbncx+xml') {
              ncxHref = href;
            } else if (properties == 'nav' ||
                (properties != null && properties.split(' ').contains('nav'))) {
              navHref = href;
            }
          }
        } catch (_) {}
      }

      // 1. Try parsing NCX
      if (ncxHref != null || spine.readAsset('toc.ncx') != null) {
        final targetNcx = ncxHref ?? 'toc.ncx';
        final resolvedNcxPath =
            (opfDir.isNotEmpty && !targetNcx.startsWith('/'))
            ? p.posix.normalize(p.posix.join(opfDir, targetNcx))
            : targetNcx;
        final ncxBytes =
            spine.readAsset(resolvedNcxPath) ??
            spine.readAsset(targetNcx) ??
            spine.readAsset('toc.ncx');
        if (ncxBytes != null && ncxBytes.isNotEmpty) {
          try {
            final ncxDoc = XmlDocument.parse(
              utf8.decode(ncxBytes, allowMalformed: true),
            );
            if (title == null || title.isEmpty) {
              final docTitle = ncxDoc.findAllElements('docTitle').firstOrNull;
              final text = docTitle
                  ?.findAllElements('text')
                  .firstOrNull
                  ?.innerText
                  .trim();
              if (text != null && text.isNotEmpty) title = text;
            }

            final navMap = ncxDoc.findAllElements('navMap').firstOrNull;
            if (navMap != null) {
              void parseNavPoints(XmlElement parent, int level) {
                for (final child in parent.findElements('navPoint')) {
                  final labelElem = child.findElements('navLabel').firstOrNull;
                  final textElem = labelElem?.findElements('text').firstOrNull;
                  final label = textElem?.innerText.trim() ?? '';

                  final contentElem = child.findElements('content').firstOrNull;
                  final src = contentElem?.getAttribute('src') ?? '';

                  final resolvedSrc =
                      (opfDir.isNotEmpty &&
                          !src.startsWith('/') &&
                          !src.contains('/'))
                      ? p.posix.join(opfDir, src)
                      : src;
                  final chapter =
                      resolveSectionIndex(src) ??
                      resolveSectionIndex(resolvedSrc) ??
                      -1;

                  outline.add(
                    OutlineItem(
                      title: label.isNotEmpty
                          ? label
                          : 'Chapter ${outline.length + 1}',
                      uri: src,
                      chapter: chapter,
                      page: chapter >= 0 ? chapter : 0,
                      level: level,
                      isOpen: false,
                    ),
                  );

                  parseNavPoints(child, level + 1);
                }
              }

              parseNavPoints(navMap, 0);
            }
          } catch (_) {}
        }
      }

      // 2. Try parsing EPUB 3 Nav if outline is still empty
      if (outline.isEmpty && navHref != null) {
        final resolvedNavPath = (opfDir.isNotEmpty && !navHref.startsWith('/'))
            ? p.posix.normalize(p.posix.join(opfDir, navHref))
            : navHref;
        final navBytes =
            spine.readAsset(resolvedNavPath) ?? spine.readAsset(navHref);
        if (navBytes != null && navBytes.isNotEmpty) {
          try {
            final navDoc = XmlDocument.parse(
              utf8.decode(navBytes, allowMalformed: true),
            );
            final navElem = navDoc
                .findAllElements('nav')
                .firstWhere(
                  (n) =>
                      n.getAttribute('epub:type') == 'toc' ||
                      n.getAttribute('type') == 'toc',
                  orElse: () => navDoc.findAllElements('nav').first,
                );

            void parseOl(XmlElement ol, int level) {
              for (final li in ol.findElements('li')) {
                final a = li.findElements('a').firstOrNull;
                if (a != null) {
                  final label = a.innerText.trim();
                  final href = a.getAttribute('href') ?? '';
                  final resolvedHref =
                      (opfDir.isNotEmpty &&
                          !href.startsWith('/') &&
                          !href.contains('/'))
                      ? p.posix.join(opfDir, href)
                      : href;
                  final chapter =
                      resolveSectionIndex(href) ??
                      resolveSectionIndex(resolvedHref) ??
                      -1;

                  outline.add(
                    OutlineItem(
                      title: label.isNotEmpty
                          ? label
                          : 'Chapter ${outline.length + 1}',
                      uri: href,
                      chapter: chapter,
                      page: chapter >= 0 ? chapter : 0,
                      level: level,
                      isOpen: false,
                    ),
                  );
                }
                for (final nestedOl in li.findElements('ol')) {
                  parseOl(nestedOl, level + 1);
                }
              }
            }

            final firstOl = navElem.findElements('ol').firstOrNull;
            if (firstOl != null) {
              parseOl(firstOl, 0);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Fallback if outline is still empty
    if (outline.isEmpty) {
      for (final sec in sections) {
        outline.add(
          OutlineItem(
            title: sec.title ?? 'Chapter ${sec.index + 1}',
            uri: sec.href,
            chapter: sec.index,
            page: sec.index,
            level: 0,
            isOpen: false,
          ),
        );
      }
    }

    return _EpubMetaAndOutline(title: title, outline: outline);
  }

  @override
  String? get title => _title;

  @override
  List<OutlineItem> get outline => List.unmodifiable(_outline);

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

    if (_assetCache.containsKey(decoded)) {
      return _assetCache[decoded];
    }
    if (_assetCache.containsKey(cleanPath)) {
      return _assetCache[cleanPath];
    }

    var bytes = _nativeSpine.readAsset(cleanPath);
    if (bytes != null && bytes.isNotEmpty) {
      _assetCache[cleanPath] = bytes;
      _assetCache[decoded] = bytes;
      return bytes;
    }

    if (decoded != cleanPath) {
      bytes = _nativeSpine.readAsset(decoded);
      if (bytes != null && bytes.isNotEmpty) {
        _assetCache[cleanPath] = bytes;
        _assetCache[decoded] = bytes;
        return bytes;
      }
    }

    final normalized = p.posix.normalize(decoded);
    if (normalized != decoded) {
      bytes = _nativeSpine.readAsset(normalized);
      if (bytes != null && bytes.isNotEmpty) {
        _assetCache[cleanPath] = bytes;
        _assetCache[decoded] = bytes;
        _assetCache[normalized] = bytes;
        return bytes;
      }
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
      _assetCache.clear();
      _nativeSpine.dispose();
      _disposed = true;
    }
  }
}
