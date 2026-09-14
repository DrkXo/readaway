import 'dart:typed_data';

import 'document_reader.dart';

/// A pluggable handler that detects and opens a specific document format.
///
/// Register handlers on [DocumentReaderFactory] to extend the set of
/// supported formats without modifying the core.
abstract class DocumentFormatHandler {
  /// Canonical format identifier (e.g. `epub`, `html`, `txt`).
  String get format;

  /// Whether this handler can open the file at [filePath].
  ///
  /// [bytes] may be provided when the caller already has the file contents
  /// in memory (e.g. sniffing magic bytes).
  bool supports(String filePath, [Uint8List? bytes]);

  /// Opens the document at [filePath], returning a ready-to-use reader.
  Future<DocumentReader> open(String filePath);
}
