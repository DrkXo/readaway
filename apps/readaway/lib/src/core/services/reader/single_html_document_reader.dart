import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'reflowable_document_reader.dart';

/// Single HTML / XHTML document reader.
///
/// Treats standalone HTML documents as a single-section reflowable document,
/// resolving embedded images and assets from the local filesystem directory.
class SingleHtmlDocumentReader implements ReflowableDocumentReader {
  final String _filePath;
  final String _htmlContent;
  final String _baseDir;

  SingleHtmlDocumentReader._({
    required String filePath,
    required this._htmlContent,
  })  : _filePath = filePath,
        _baseDir = p.dirname(filePath);

  /// Opens a standalone HTML document from [filePath].
  static Future<SingleHtmlDocumentReader> fromFile(String filePath) async {
    final file = File(filePath);
    final htmlContent = await file.readAsString();
    return SingleHtmlDocumentReader._(
      filePath: filePath,
      htmlContent: htmlContent,
    );
  }

  @override
  int get sectionCount => 1;

  @override
  List<ReflowableSectionItem> get sections => [
        ReflowableSectionItem(
          index: 0,
          id: 'section_0',
          href: p.basename(_filePath),
          mediaType: 'text/html',
        ),
      ];

  @override
  String loadSectionHtml(int index) {
    if (index != 0) {
      throw RangeError.range(index, 0, 0, 'index');
    }
    return _htmlContent;
  }

  @override
  Uint8List? loadAssetBytes(String assetPath) {
    try {
      final cleanPath = assetPath.startsWith('/') ? assetPath.substring(1) : assetPath;
      final stripped = cleanPath.split('?').first.split('#').first;
      final decoded = Uri.decodeComponent(stripped);

      // Try decoded full path
      var fullPath = p.normalize(p.join(_baseDir, decoded));
      var file = File(fullPath);
      if (file.existsSync()) {
        return file.readAsBytesSync();
      }

      // Try raw cleanPath if different
      if (cleanPath != decoded) {
        fullPath = p.normalize(p.join(_baseDir, cleanPath));
        file = File(fullPath);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) {
    final cleanHref = relativeHref.split('?').first.split('#').first;
    return Uri.decodeComponent(cleanHref);
  }

  @override
  int? resolveSectionIndex(String href) {
    return 0;
  }

  @override
  void dispose() {
    // No native resources to release
  }
}
