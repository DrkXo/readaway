import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../abstracts/document_format_handler.dart';
import '../abstracts/document_reader.dart';
import 'plain_text_document_reader.dart';
import 'rust_cbz_document_reader.dart';
import 'rust_epub_document_reader.dart';
import 'single_html_document_reader.dart';

/// Built-in handler for EPUB documents.
class EpubFormatHandler implements DocumentFormatHandler {
  const EpubFormatHandler();

  @override
  String get format => 'epub';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    if (p.extension(filePath).toLowerCase() == '.epub') return true;
    if (bytes != null && bytes.length >= 28) {
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
      RustEpubDocumentReader.open(filePath);
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
    if (!(bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04)) {
      return false;
    }
    if (_isEpubZipBytes(bytes)) return false;
    return true;
  }

  @override
  Future<DocumentReader> open(String filePath) =>
      RustCbzDocumentReader.open(filePath);
}

/// Helper that checks if ZIP bytes contain an EPUB mimetype entry.
bool _isEpubZipBytes(Uint8List bytes) {
  if (bytes.length < 58) return false;
  // Look for "mimetype" and "application/epub+zip" within the first 256 bytes
  final limit = bytes.length < 256 ? bytes.length : 256;
  final sample = latin1.decode(bytes.sublist(0, limit), allowInvalid: true);
  return sample.contains('mimetype') && sample.contains('application/epub+zip');
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
    final ext = p.extension(filePath).toLowerCase();
    return ext == '.txt' || ext == '.text' || ext == '.log';
  }

  @override
  Future<DocumentReader> open(String filePath) =>
      PlainTextDocumentReader.fromFile(filePath);
}
