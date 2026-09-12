import 'dart:io';
import 'dart:typed_data';

import '../abstracts/document_format_handler.dart';
import '../abstracts/document_reader.dart';
import '../errors/document_exception.dart';
import 'builtin_handlers.dart';

/// Registry-based factory that opens documents by auto-detecting their format.
///
/// New formats are added by registering a [DocumentFormatHandler]; no core
/// changes are required.
class DocumentReaderFactory {
  final List<DocumentFormatHandler> _handlers = [];
  final Map<String, DocumentFormatHandler> _byFormat = {};

  /// Creates a factory pre-registered with the built-in handlers
  /// (EPUB, CBZ, HTML, plain text).
  DocumentReaderFactory() {
    register(const EpubFormatHandler());
    register(const CbzFormatHandler());
    register(const HtmlFormatHandler());
    register(const TextFormatHandler());
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
  /// [bytes] may be provided to sniff magic bytes without reading the file.
  /// Throws [UnsupportedFormatException] when no handler supports the file.
  Future<DocumentReader> open(String filePath, {Uint8List? bytes}) async {
    var sniffBytes = bytes;
    for (final handler in _handlers) {
      if (handler.supports(filePath, sniffBytes)) {
        return handler.open(filePath);
      }
    }
    // No handler matched by extension; try sniffing magic bytes from disk.
    if (sniffBytes == null) {
      final file = File(filePath);
      if (file.existsSync()) {
        sniffBytes = file.readAsBytesSync();
        for (final handler in _handlers) {
          if (handler.supports(filePath, sniffBytes)) {
            return handler.open(filePath);
          }
        }
      }
    }
    throw UnsupportedFormatException('No handler supports: $filePath');
  }
}
