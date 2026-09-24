import 'dart:io';
import 'dart:typed_data';

import '../abstracts/document_format_handler.dart';
import '../abstracts/document_reader.dart';
import '../errors/document_exception.dart';
import '../logger/app_logger.dart';
import 'builtin_handlers.dart';

/// Registry-based factory that opens documents by auto-detecting their format.
///
/// Pre-registers handlers for EPUB, PDF, CBZ, CBT, CBR, CB7, HTML, and plain text.
class DocumentReaderFactory {
  final _log = AppLogger.instance.scope('DocumentReaderFactory');

  final List<DocumentFormatHandler> _handlers = [];
  final Map<String, DocumentFormatHandler> _byFormat = {};

  /// Creates a factory pre-registered with all built-in handlers.
  DocumentReaderFactory() {
    register(const EpubFormatHandler());
    register(const PdfFormatHandler());
    register(const CbzFormatHandler());
    register(const CbtFormatHandler());
    register(const CbrFormatHandler());
    register(const Cb7FormatHandler());
    register(const HtmlFormatHandler());
    register(const TextFormatHandler());
    register(const MarkdownFormatHandler());
  }

  /// Registers [handler], replacing any existing handler for the same format.
  void register(DocumentFormatHandler handler) {
    final existing = _byFormat[handler.format];
    if (existing != null) {
      _handlers.remove(existing);
    }
    _handlers.add(handler);
    _byFormat[handler.format] = handler;
  }

  /// Unregisters the handler for [format], if present.
  void unregister(String format) {
    final existing = _byFormat.remove(format);
    if (existing != null) {
      _handlers.remove(existing);
    }
  }

  /// Registered handlers, in registration order.
  List<DocumentFormatHandler> get handlers => List.unmodifiable(_handlers);

  /// Opens the document at [filePath], auto-detecting its format.
  ///
  /// [password] may be provided for password-protected/encrypted documents.
  /// [bytes] may be provided to sniff magic bytes without reading the file.
  /// Throws [UnsupportedFormatException] when no handler supports the file.
  Future<DocumentReader> open(
    String filePath, {
    Uint8List? bytes,
    String? password,
  }) async {
    _log.i('Opening document: $filePath');
    var sniffBytes = bytes;
    for (final handler in _handlers) {
      if (handler.supports(filePath, sniffBytes)) {
        _log.d('Matched handler "${handler.format}" for $filePath');
        return handler.open(filePath, password: password);
      }
    }
    // No handler matched by extension; try sniffing magic bytes from disk.
    if (sniffBytes == null) {
      final file = File(filePath);
      if (file.existsSync()) {
        try {
          _log.d('Sniffing magic bytes from disk for: $filePath');
          sniffBytes = file.readAsBytesSync();
          for (final handler in _handlers) {
            if (handler.supports(filePath, sniffBytes)) {
              _log.d('Matched handler "${handler.format}" via magic bytes for $filePath');
              return await handler.open(filePath, password: password);
            }
          }
        } catch (e, st) {
          _log.w('Failed to read file bytes while sniffing: $filePath', error: e, stackTrace: st);
        }
      }
    }
    _log.w('No handler supports document format: $filePath');
    throw UnsupportedFormatException('No handler supports: $filePath');
  }
}
