import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'reflowable_document_reader.dart';

/// Plain text (.txt) document reader.
///
/// Wraps text blocks into semantic HTML paragraphs for clean reflow in HyperRender.
class PlainTextDocumentReader implements ReflowableDocumentReader {
  final String _filePath;
  final String _htmlContent;

  PlainTextDocumentReader._({
    required this._filePath,
    required this._htmlContent,
  });

  /// Opens a plain text document from [filePath].
  static Future<PlainTextDocumentReader> fromFile(String filePath) async {
    final file = File(filePath);
    final rawText = await file.readAsString();
    final html = _textToHtml(rawText);
    return PlainTextDocumentReader._(
      filePath: filePath,
      htmlContent: html,
    );
  }

  static String _textToHtml(String text) {
    final escaped = const HtmlEscape().convert(text);
    final paragraphs = escaped.split(RegExp(r'\r?\n\s*\r?\n'));
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html><html><head><meta charset="utf-8"></head><body>');
    for (final para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isNotEmpty) {
        // Convert single line breaks to <br/>
        final withBrs = trimmed.replaceAll(RegExp(r'\r?\n'), '<br/>');
        buffer.writeln('<p>$withBrs</p>');
      }
    }
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  @override
  int get sectionCount => 1;

  @override
  List<ReflowableSectionItem> get sections => [
        ReflowableSectionItem(
          index: 0,
          id: 'section_0',
          href: p.basename(_filePath),
          mediaType: 'text/plain',
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
  Uint8List? loadAssetBytes(String assetPath) => null;

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) => relativeHref;

  @override
  int? resolveSectionIndex(String href) => 0;

  @override
  void dispose() {}
}
