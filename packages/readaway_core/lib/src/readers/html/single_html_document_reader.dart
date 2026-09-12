import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;

import '../../abstracts/reflowable_document_reader.dart';
import '../../errors/document_exception.dart';
import '../../models/models.dart';

/// Reads a standalone HTML file as a single-section reflowable document.
///
/// Embedded assets (images, fonts, CSS) are resolved from the file's
/// directory on disk.
class SingleHtmlDocumentReader implements ReflowableDocumentReader {
  final String _filePath;
  final String _baseDir;
  final String _html;
  final String? _title;
  final List<OutlineItem> _outline;
  bool _disposed = false;

  SingleHtmlDocumentReader._({
    required this._filePath,
    required this._baseDir,
    required this._html,
    required this._title,
    required this._outline,
  });

  /// Opens a standalone HTML document from [filePath].
  static Future<SingleHtmlDocumentReader> fromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('HTML file not found: $filePath');
    }
    final bytes = file.readAsBytesSync();
    final html = utf8.decode(bytes, allowMalformed: true);
    final title = _extractTitle(html);
    final baseName = p.basename(filePath);
    return SingleHtmlDocumentReader._(
      filePath: filePath,
      baseDir: p.dirname(filePath),
      html: html,
      title: title,
      outline: [
        OutlineItem(
          title: title ?? p.basenameWithoutExtension(filePath),
          href: baseName,
          level: 0,
        ),
      ],
    );
  }

  static String? _extractTitle(String html) {
    try {
      final dom.Document doc = html_parser.parse(html);
      final title = doc.querySelector('title')?.text.trim();
      return (title == null || title.isEmpty) ? null : title;
    } catch (_) {
      return null;
    }
  }

  @override
  String get format => 'html';

  @override
  bool get isReflowable => true;

  @override
  String? get title => _title;

  @override
  DocumentMetadata? get metadata => null;

  @override
  List<OutlineItem> get outline => _outline;

  @override
  String? get coverImagePath => null;

  @override
  int get sectionCount => 1;

  @override
  List<DocumentSection> get sections => [
    DocumentSection(
      index: 0,
      id: 'html',
      href: p.basename(_filePath),
      mediaType: 'text/html',
      title: _title,
    ),
  ];

  @override
  String loadSectionHtml(int index) {
    _checkNotDisposed();
    if (index != 0) {
      throw RangeError.range(index, 0, 0, 'index', 'single-section document');
    }
    return _html;
  }

  @override
  Uint8List? loadAsset(String assetPath) {
    _checkNotDisposed();
    final resolved = _resolvePath(assetPath);
    final file = File(resolved);
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  }

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) =>
      _resolvePath(relativeHref);

  String _resolvePath(String relativeHref) {
    if (relativeHref.startsWith('/')) {
      return p.normalize(relativeHref);
    }
    return p.normalize(p.join(_baseDir, relativeHref));
  }

  @override
  int? resolveSectionIndex(String href) {
    if (href.isEmpty) return null;
    final clean = href.split('#').first.split('?').first;
    if (clean.isEmpty) return null;
    if (p.basename(clean) == p.basename(_filePath)) return 0;
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw DocumentDisposedException(
        'SingleHtmlDocumentReader has been disposed',
      );
    }
  }
}
