import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../abstracts/reflowable_document_reader.dart';
import '../../errors/document_exception.dart';
import '../../models/models.dart';

/// Reads a plain-text file, wrapping its content into semantic HTML.
///
/// The whole file is exposed as a single section; paragraphs are separated
/// by blank lines and rendered as `<p>` elements with `<br/>` line breaks.
class PlainTextDocumentReader implements ReflowableDocumentReader {
  final String _filePath;
  final String _html;
  final String? _title;
  final List<OutlineItem> _outline;
  bool _disposed = false;

  PlainTextDocumentReader._({
    required this._filePath,
    required this._html,
    required this._title,
    required this._outline,
  });

  /// Opens a plain-text document from [filePath].
  static Future<PlainTextDocumentReader> fromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('Text file not found: $filePath');
    }
    final bytes = file.readAsBytesSync();
    final text = utf8.decode(bytes, allowMalformed: true);
    final title = p.basenameWithoutExtension(filePath);
    return PlainTextDocumentReader._(
      filePath: filePath,
      html: _textToHtml(text),
      title: title,
      outline: [
        OutlineItem(title: title, href: p.basename(filePath), level: 0),
      ],
    );
  }

  /// Wraps plain text into semantic HTML (`<p>` + `<br/>`) for rendering.
  static String _textToHtml(String text) {
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    final buffer = StringBuffer('<html><body>');
    for (final para in paragraphs) {
      final lines = para
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;
      buffer.write('<p>');
      for (var i = 0; i < lines.length; i++) {
        if (i > 0) buffer.write('<br/>');
        buffer.write(_escapeHtml(lines[i]));
      }
      buffer.write('</p>');
    }
    buffer.write('</body></html>');
    return buffer.toString();
  }

  static String _escapeHtml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  @override
  String get format => 'txt';

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
      id: 'txt',
      href: p.basename(_filePath),
      mediaType: 'text/plain',
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
  Uint8List? loadAsset(String assetPath) => null;

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) =>
      relativeHref;

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
        'PlainTextDocumentReader has been disposed',
      );
    }
  }
}
