import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

import '../abstracts/document_format_handler.dart';
import '../abstracts/document_reader.dart';
import '../errors/document_exception.dart';
import 'cbz_document_reader.dart';
import 'epub_document_reader.dart';
import 'pdf/pdf_document_reader.dart';
import 'plain_text_document_reader.dart';
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
  Future<DocumentReader> open(String filePath, {String? password}) =>
      EpubDocumentReader.open(filePath);
}

/// Built-in handler for PDF documents.
class PdfFormatHandler implements DocumentFormatHandler {
  const PdfFormatHandler();

  @override
  String get format => 'pdf';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    if (p.extension(filePath).toLowerCase() == '.pdf') return true;
    if (bytes != null && bytes.length >= 4) {
      return bytes[0] == 0x25 && // %
          bytes[1] == 0x50 && // P
          bytes[2] == 0x44 && // D
          bytes[3] == 0x46; // F
    }
    return false;
  }

  @override
  Future<DocumentReader> open(String filePath, {String? password}) =>
      PdfDocumentReader.open(filePath, password: password);
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
  Future<DocumentReader> open(String filePath, {String? password}) =>
      ComicBookDocumentReader.open(filePath, password: password);
}

/// Built-in handler for CBT (Comic Book TAR) documents.
class CbtFormatHandler implements DocumentFormatHandler {
  const CbtFormatHandler();

  @override
  String get format => 'cbt';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.cbt' || ext == '.tar') return true;
    if (bytes != null && bytes.length >= 262) {
      // Check for POSIX ustar magic at offset 257
      if (bytes[257] == 0x75 && // u
          bytes[258] == 0x73 && // s
          bytes[259] == 0x74 && // t
          bytes[260] == 0x61 && // a
          bytes[261] == 0x72) { // r
        return true;
      }
    }
    return false;
  }

  @override
  Future<DocumentReader> open(String filePath, {String? password}) =>
      ComicBookDocumentReader.open(filePath, password: password);
}

/// Built-in handler for CBR (Comic Book RAR) documents.
class CbrFormatHandler implements DocumentFormatHandler {
  const CbrFormatHandler();

  @override
  String get format => 'cbr';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.cbr' || ext == '.rar') return true;
    if (bytes != null && bytes.length >= 7) {
      // RAR4: 52 61 72 21 1A 07 00
      // RAR5: 52 61 72 21 1A 07 01 00
      return bytes[0] == 0x52 &&
          bytes[1] == 0x61 &&
          bytes[2] == 0x72 &&
          bytes[3] == 0x21 &&
          bytes[4] == 0x1A &&
          bytes[5] == 0x07;
    }
    return false;
  }

  @override
  Future<DocumentReader> open(String filePath, {String? password}) =>
      ComicBookDocumentReader.open(filePath, password: password);
}

/// Built-in handler for CB7 (Comic Book 7z) documents.
class Cb7FormatHandler implements DocumentFormatHandler {
  const Cb7FormatHandler();

  @override
  String get format => 'cb7';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.cb7' || ext == '.7z') return true;
    if (bytes != null && bytes.length >= 6) {
      // 7z signature: 37 7A BC AF 27 1C
      return bytes[0] == 0x37 &&
          bytes[1] == 0x7A &&
          bytes[2] == 0xBC &&
          bytes[3] == 0xAF &&
          bytes[4] == 0x27 &&
          bytes[5] == 0x1C;
    }
    return false;
  }

  @override
  Future<DocumentReader> open(String filePath, {String? password}) =>
      ComicBookDocumentReader.open(filePath, password: password);
}

/// Helper that checks if ZIP bytes contain an EPUB mimetype entry.
bool _isEpubZipBytes(Uint8List bytes) {
  if (bytes.length < 58) return false;
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
  Future<DocumentReader> open(String filePath, {String? password}) =>
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
  Future<DocumentReader> open(String filePath, {String? password}) =>
      PlainTextDocumentReader.fromFile(filePath);
}

/// Built-in handler for Markdown documents.
class MarkdownFormatHandler implements DocumentFormatHandler {
  const MarkdownFormatHandler();

  @override
  String get format => 'md';

  @override
  bool supports(String filePath, [Uint8List? bytes]) {
    final ext = p.extension(filePath).toLowerCase();
    return ext == '.md' || ext == '.markdown';
  }

  @override
  Future<DocumentReader> open(String filePath, {String? password}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('Markdown file not found: $filePath');
    }
    final source = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    final body = md.markdownToHtml(source);
    final html = '<html><body>$body</body></html>';
    return SingleHtmlDocumentReader.fromHtml(
      html,
      filePath: filePath,
      title: _extractTitle(source),
    );
  }

  static String? _extractTitle(String source) {
    final firstNonBlank = source
        .split('\n')
        .indexWhere((line) => line.trim().isNotEmpty);
    if (firstNonBlank < 0) return null;
    final match = RegExp(r'^\s{0,3}#\s+(.+)$')
        .firstMatch(source.split('\n')[firstNonBlank]);
    return match?.group(1)?.trim();
  }
}
