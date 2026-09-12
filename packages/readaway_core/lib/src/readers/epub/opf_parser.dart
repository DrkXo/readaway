import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../../readaway_core.dart';

/// Parses the EPUB container + package document (OPF).
class OpfParser {
  const OpfParser();

  /// Locates the OPF path from `META-INF/container.xml`.
  ///
  /// Returns `null` when the container is missing or malformed.
  String? findOpfPath(EpubContainer container) =>
      findOpfPathFromBytes(container.readEntry('META-INF/container.xml'));

  /// Locates the OPF path from raw `META-INF/container.xml` bytes.
  ///
  /// Returns `null` when the bytes are missing or malformed.
  String? findOpfPathFromBytes(Uint8List? containerXmlBytes) {
    if (containerXmlBytes == null || containerXmlBytes.isEmpty) return null;
    try {
      final doc = XmlDocument.parse(
        utf8.decode(containerXmlBytes, allowMalformed: true),
      );
      final rootfile = doc.findAllElements('rootfile').firstOrNull;
      return rootfile?.getAttribute('full-path');
    } catch (_) {
      return null;
    }
  }

  /// Parses the OPF at [opfPath] (or a discovered fallback) into [OpfData].
  ///
  /// Throws [DocumentParseException] when no readable OPF is found.
  OpfData parse(EpubContainer container, {String? opfPath}) {
    final resolvedOpf = opfPath ?? findFallbackOpf(container);
    if (resolvedOpf == null) {
      throw DocumentParseException('No OPF package document found in EPUB');
    }
    final bytes = container.readEntry(resolvedOpf);
    if (bytes == null || bytes.isEmpty) {
      throw DocumentParseException(
        'OPF package document is empty: $resolvedOpf',
      );
    }
    final opfDir = resolvedOpf.contains('/')
        ? p.posix.dirname(resolvedOpf)
        : '';
    return parseBytes(bytes, opfDir: opfDir);
  }

  /// Parses raw OPF [bytes] into [OpfData].
  ///
  /// [opfDir] is the directory containing the OPF, used to resolve relative
  /// paths. This entry point is isolate-friendly: it only needs the OPF bytes,
  /// not a container.
  OpfData parseBytes(Uint8List bytes, {String opfDir = ''}) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
    } catch (e) {
      throw DocumentParseException('Malformed OPF package document', cause: e);
    }

    final metadata = _parseMetadata(doc);
    final manifest = _parseManifest(doc);
    final sections = _parseSpine(doc, manifest, opfDir);

    String? ncxHref;
    String? navHref;
    for (final item in doc.findAllElements('item')) {
      final mediaType = item.getAttribute('media-type');
      final properties = item.getAttribute('properties');
      final href = item.getAttribute('href');
      if (href == null || href.isEmpty) continue;
      if (mediaType == 'application/x-dtbncx+xml') {
        ncxHref = href;
      } else if (properties != null && properties.split(' ').contains('nav')) {
        navHref = href;
      }
    }

    return OpfData(
      metadata: metadata,
      sections: sections,
      ncxHref: ncxHref,
      navHref: navHref,
      opfDir: opfDir,
      coverImagePath: _parseCoverImagePath(doc, manifest, opfDir),
    );
  }

  /// Detects the cover image path from OPF metadata/manifest.
  ///
  /// EPUB 3: `<item properties="cover-image">`. EPUB 2:
  /// `<meta name="cover" content="<manifest-id>"/>` referencing a manifest
  /// item. Returns `null` when no cover is declared.
  String? _parseCoverImagePath(
    XmlDocument doc,
    Map<String, ({String href, String mediaType})> manifest,
    String opfDir,
  ) {
    // EPUB 3: item with properties="cover-image".
    for (final item in doc.findAllElements('item')) {
      final properties = item.getAttribute('properties');
      if (properties != null && properties.split(' ').contains('cover-image')) {
        final href = item.getAttribute('href');
        if (href != null && href.isNotEmpty) {
          return _resolveHref(href, opfDir);
        }
      }
    }
    // EPUB 2: <meta name="cover" content="<manifest-id>"/>.
    for (final meta in doc.findAllElements('meta')) {
      if (meta.getAttribute('name') == 'cover') {
        final id = meta.getAttribute('content');
        if (id != null) {
          final manifestItem = manifest[id];
          if (manifestItem != null) {
            return _resolveHref(manifestItem.href, opfDir);
          }
        }
      }
    }
    return null;
  }

  /// Finds a fallback OPF path by common convention.
  String? findFallbackOpf(EpubContainer container) {
    for (final candidate in ['content.opf', 'book.opf', 'OEBPS/content.opf']) {
      if (container.hasEntry(candidate)) return candidate;
    }
    return null;
  }

  DocumentMetadata _parseMetadata(XmlDocument doc) {
    String? textOf(String name) {
      final el = doc.findAllElements(name).firstOrNull;
      final t = el?.innerText.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    DateTime? modified;
    for (final meta in doc.findAllElements('meta')) {
      if (meta.getAttribute('property') == 'dcterms:modified') {
        modified = _parseDate(meta.innerText.trim());
        break;
      }
    }

    return DocumentMetadata(
      title: textOf('dc:title'),
      creator: textOf('dc:creator'),
      language: textOf('dc:language'),
      identifier: textOf('dc:identifier'),
      publisher: textOf('dc:publisher'),
      description: textOf('dc:description'),
      subject: textOf('dc:subject'),
      modified: modified,
    );
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, ({String href, String mediaType})> _parseManifest(
    XmlDocument doc,
  ) {
    final manifest = <String, ({String href, String mediaType})>{};
    for (final item in doc.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id == null || href == null) continue;
      manifest[id] = (
        href: href,
        mediaType:
            item.getAttribute('media-type') ?? 'application/octet-stream',
      );
    }
    return manifest;
  }

  List<DocumentSection> _parseSpine(
    XmlDocument doc,
    Map<String, ({String href, String mediaType})> manifest,
    String opfDir,
  ) {
    final sections = <DocumentSection>[];
    var index = 0;
    for (final itemref in doc.findAllElements('itemref')) {
      final idref = itemref.getAttribute('idref');
      if (idref == null) continue;
      final manifestItem = manifest[idref];
      if (manifestItem == null) continue;
      sections.add(
        DocumentSection(
          index: index,
          id: idref,
          href: _resolveHref(manifestItem.href, opfDir),
          mediaType: manifestItem.mediaType,
        ),
      );
      index++;
    }
    return sections;
  }

  /// Resolves a manifest href relative to the OPF directory.
  static String _resolveHref(String href, String opfDir) {
    if (opfDir.isEmpty) return p.posix.normalize(href);
    if (href.startsWith('/')) return p.posix.normalize(href.substring(1));
    return p.posix.normalize(p.posix.join(opfDir, href));
  }
}
