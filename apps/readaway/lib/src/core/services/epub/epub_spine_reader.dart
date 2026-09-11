import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Represents a single spine item (chapter / document section) in an EPUB.
class EpubSpineItem {
  final int index;
  final String id;
  final String href;
  final String mediaType;
  final String? title;

  const EpubSpineItem({
    required this.index,
    required this.id,
    required this.href,
    required this.mediaType,
    this.title,
  });

  @override
  String toString() => 'EpubSpineItem(index: $index, id: $id, href: $href)';
}

/// Fast, lightweight EPUB spine and asset extractor built on `package:archive`.
///
/// Designed to extract raw, semantic XHTML for fluid reflow engines (e.g. HyperRender)
/// without altering author markup or injecting fixed pixel coordinates.
class EpubSpineReader {
  final List<EpubSpineItem> _spineItems;
  final Map<String, ArchiveFile> _fileByPath;

  const EpubSpineReader._({
    required this._spineItems,
    required this._fileByPath,
  });

  /// Opens an EPUB file at [filePath] and parses its container and OPF package document.
  static Future<EpubSpineReader> fromFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return fromBytes(bytes);
  }

  /// Opens an EPUB from in-memory [bytes].
  static EpubSpineReader fromBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final fileByPath = <String, ArchiveFile>{};
    for (final file in archive.files) {
      if (file.isFile) {
        // Normalize path by removing leading slashes
        final cleanPath = file.name.startsWith('/')
            ? file.name.substring(1)
            : file.name;
        fileByPath[cleanPath] = file;
      }
    }

    // 1. Locate rootfile from META-INF/container.xml
    final containerFile = fileByPath['META-INF/container.xml'];
    if (containerFile == null) {
      throw const FormatException('Invalid EPUB: META-INF/container.xml not found');
    }

    final containerXml = XmlDocument.parse(utf8.decode(containerFile.content as List<int>));
    final rootfileElem = containerXml.findAllElements('rootfile').firstOrNull;
    final opfPath = rootfileElem?.getAttribute('full-path');
    if (opfPath == null || opfPath.isEmpty) {
      throw const FormatException('Invalid EPUB: OPF rootfile path not declared in container.xml');
    }

    final cleanOpfPath = opfPath.startsWith('/') ? opfPath.substring(1) : opfPath;
    final opfFile = fileByPath[cleanOpfPath];
    if (opfFile == null) {
      throw FormatException('Invalid EPUB: OPF file "$cleanOpfPath" not found');
    }

    final opfDir = p.posix.dirname(cleanOpfPath);
    final opfXml = XmlDocument.parse(utf8.decode(opfFile.content as List<int>));

    // 2. Parse Manifest
    final manifestHrefById = <String, String>{};
    final manifestMediaTypes = <String, String>{};
    final manifestElems = opfXml.findAllElements('item');
    for (final elem in manifestElems) {
      final id = elem.getAttribute('id');
      final href = elem.getAttribute('href');
      final mediaType = elem.getAttribute('media-type') ?? 'application/xhtml+xml';
      if (id != null && href != null) {
        manifestHrefById[id] = Uri.decodeComponent(href);
        manifestMediaTypes[id] = mediaType;
      }
    }

    // 3. Parse Spine
    final spineItems = <EpubSpineItem>[];
    final itemrefElems = opfXml.findAllElements('itemref');
    int spineIndex = 0;
    for (final itemref in itemrefElems) {
      final idref = itemref.getAttribute('idref');
      if (idref != null && manifestHrefById.containsKey(idref)) {
        final relHref = manifestHrefById[idref]!;
        // Resolve href relative to OPF directory
        final fullHref = (opfDir == '.' || opfDir.isEmpty)
            ? relHref
            : p.posix.normalize(p.posix.join(opfDir, relHref));

        spineItems.add(
          EpubSpineItem(
            index: spineIndex++,
            id: idref,
            href: fullHref,
            mediaType: manifestMediaTypes[idref] ?? 'application/xhtml+xml',
          ),
        );
      }
    }

    return EpubSpineReader._(
      spineItems: spineItems,
      fileByPath: fileByPath,
    );
  }

  /// Total number of spine items (chapters) in the document.
  int get spineCount => _spineItems.length;

  /// Ordered list of spine items.
  List<EpubSpineItem> get spineItems => List.unmodifiable(_spineItems);

  /// Retrieves the raw XHTML string for the spine item at [index].
  String loadSpineHtml(int index) {
    if (index < 0 || index >= _spineItems.length) {
      throw RangeError.range(index, 0, _spineItems.length - 1, 'index');
    }
    final item = _spineItems[index];
    final file = _fileByPath[item.href];
    if (file == null) {
      throw StateError('Spine file "${item.href}" not found in EPUB archive');
    }
    return utf8.decode(file.content as List<int>);
  }

  /// Retrieves raw binary content for an asset (e.g. image, font, stylesheet) at [assetPath].
  List<int>? loadAssetBytes(String assetPath) {
    final cleanPath = assetPath.startsWith('/') ? assetPath.substring(1) : assetPath;
    return _fileByPath[cleanPath]?.content as List<int>?;
  }

  /// Resolves an asset path relative to a spine item.
  String resolveAssetPath(int spineIndex, String relativeHref) {
    if (spineIndex < 0 || spineIndex >= _spineItems.length) {
      return relativeHref;
    }
    final spineHref = _spineItems[spineIndex].href;
    final spineDir = p.posix.dirname(spineHref);
    return p.posix.normalize(p.posix.join(spineDir, relativeHref));
  }
}
