/// Error hierarchy for document reading and parsing failures.
library;

/// Base class for all document-related errors thrown by `readaway_core`.
class DocumentException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  /// The underlying cause, if any.
  final Object? cause;

  const DocumentException(this.message, {this.cause});

  @override
  String toString() =>
      '$runtimeType: $message${cause == null ? '' : ' (cause: $cause)'}';
}

/// Thrown when a document file cannot be opened or read from disk.
class DocumentOpenException extends DocumentException {
  const DocumentOpenException(super.message, {super.cause});
}

/// Thrown when a document opens but its content is malformed or unreadable.
class DocumentParseException extends DocumentException {
  const DocumentParseException(super.message, {super.cause});
}

/// Thrown when no registered [DocumentFormatHandler] supports the given file.
class UnsupportedFormatException extends DocumentException {
  const UnsupportedFormatException(super.message, {super.cause});
}

/// Thrown when an operation is attempted on a reader that has been disposed.
class DocumentDisposedException extends DocumentException {
  const DocumentDisposedException(super.message, {super.cause});
}

/// Thrown when a document requires a password or when the supplied password is incorrect.
class DocumentEncryptedException extends DocumentException {
  /// True if a password was supplied but was incorrect;
  /// False if no password was supplied and the document is locked.
  final bool isInvalidPassword;

  const DocumentEncryptedException(
    super.message, {
    this.isInvalidPassword = false,
    super.cause,
  });
}
