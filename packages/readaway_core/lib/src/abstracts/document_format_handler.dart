import 'dart:typed_data';

import 'document_reader.dart';

/// Pluggable format handler for document auto-detection and opening.
abstract class DocumentFormatHandler {
  /// Unique format tag (e.g. `epub`, `cbz`, `txt`).
  String get format;

  /// Returns true if this handler can open the file at [filePath].
  bool supports(String filePath, [Uint8List? bytes]);

  /// Opens the document at [filePath], optionally using [password] for decryption.
  Future<DocumentReader> open(String filePath, {String? password});
}
