import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../abstracts/document_format_handler.dart';
import '../abstracts/document_reader.dart';
import 'cbz/cbz_document_reader.dart';
import 'epub/epub_document_reader.dart';
import 'html/single_html_document_reader.dart';
import 'text/plain_text_document_reader.dart';

/// Built-in handler for EPUB documents.
class EpubFormatHandler implements DocumentFormatHandler {
  const EpubFormatHandler();

  @override
  String get format => 'epub';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    if (p.extension(filePath).toLowerCase() == '.epub') return true;
    // Sniff ZIP magic bytes when the extension is unknown, but require the
    // EPUB `mimetype` entry so we don't claim CBZ/generic ZIP archives.
    if (bytes != null && bytes.length >= 4) {
      if (bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04) {
        return _isEpubZipBytes(bytes);
      }
    }
    return false;
  }

  @override
  Future<DocumentReader> open(String filePath) =>
      EpubDocumentReader.fromFile(filePath);
}

/// Built-in handler for CBZ (Comic Book ZIP) documents.
class CbzFormatHandler implements DocumentFormatHandler {
  const CbzFormatHandler();

  @override
  String get format => 'cbz';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    if (p.extension(filePath).toLowerCase() == '.cbz') return true;
    if (bytes == null || bytes.length < 4) return false;
    // ZIP magic bytes.
    if (!(bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04)) {
      return false;
    }
    // A ZIP with image entries and no EPUB `mimetype` entry is a CBZ.
    if (_isEpubZipBytes(bytes)) return false;
    return _hasImageEntries(bytes);
  }

  @override
  Future<DocumentReader> open(String filePath) async =>
      CbzDocumentReader.fromFile(filePath);
}

/// Returns true when [bytes] is a ZIP archive containing an EPUB `mimetype`
/// entry (i.e. it is an EPUB container, not a generic ZIP/CBZ).
bool _isEpubZipBytes(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      if (file.isFile && file.name == 'mimetype') {
        final content = file.content;
        return utf8.decode(content, allowMalformed: true).trim() ==
            'application/epub+zip';
      }
    }
    return false;
  } on ArchiveException {
    return false;
  }
}

/// Returns true when [bytes] is a ZIP archive containing at least one page
/// image entry.
bool _hasImageEntries(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      if (file.isFile && CbzDocumentReader.isImagePath(file.name)) {
        return true;
      }
    }
    return false;
  } on ArchiveException {
    return false;
  }
}

/// Built-in handler for standalone HTML documents.
class HtmlFormatHandler implements DocumentFormatHandler {
  const HtmlFormatHandler();

  @override
  String get format => 'html';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    final ext = p.extension(filePath).toLowerCase();
    return ext == '.html' || ext == '.htm' || ext == '.xhtml';
  }

  @override
  Future<DocumentReader> open(String filePath) =>
      SingleHtmlDocumentReader.fromFile(filePath);
}

/// Built-in handler for plain-text documents.
class TextFormatHandler implements DocumentFormatHandler {
  const TextFormatHandler();

  @override
  String get format => 'txt';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    return p.extension(filePath).toLowerCase() == '.txt';
  }

  @override
  Future<DocumentReader> open(String filePath) =>
      PlainTextDocumentReader.fromFile(filePath);
}
