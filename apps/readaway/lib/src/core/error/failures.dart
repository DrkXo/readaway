import 'package:equatable/equatable.dart';

/// Sealed base class for all application failures.
///
/// Designed to be used with `fpdart` (`Either<Failure, T>` and `TaskEither<Failure, T>`).
/// Subclasses categorize domain failures so UI components can pattern-match and display
/// targeted error views, recovery prompts, and diagnostics without crashing or throwing.
sealed class Failure extends Equatable {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.cause, this.stackTrace});

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

// ---------------------------------------------------------------------------
// Document Failures
// ---------------------------------------------------------------------------

sealed class DocumentFailure extends Failure {
  const DocumentFailure(super.message, {super.cause, super.stackTrace});
}

class DocumentNotFoundFailure extends DocumentFailure {
  final String path;
  const DocumentNotFoundFailure(
    this.path, {
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
         'Document not found at path: $path',
         cause: cause,
         stackTrace: stackTrace,
       );

  @override
  List<Object?> get props => [path, message, cause];
}

class UnsupportedDocumentFormatFailure extends DocumentFailure {
  final String format;
  const UnsupportedDocumentFormatFailure(
    this.format, {
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
         'Unsupported document format: $format',
         cause: cause,
         stackTrace: stackTrace,
       );

  @override
  List<Object?> get props => [format, message, cause];
}

class CorruptDocumentFailure extends DocumentFailure {
  const CorruptDocumentFailure(super.message, {super.cause, super.stackTrace});
}

class DocumentParseFailure extends DocumentFailure {
  const DocumentParseFailure(super.message, {super.cause, super.stackTrace});
}

class DocumentCancelledFailure extends DocumentFailure {
  const DocumentCancelledFailure([
    super.message = 'Document selection was cancelled',
  ]);
}

// ---------------------------------------------------------------------------
// Storage Failures
// ---------------------------------------------------------------------------

sealed class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause, super.stackTrace});
}

class StorageReadFailure extends StorageFailure {
  final String key;
  const StorageReadFailure(this.key, {Object? cause, StackTrace? stackTrace})
    : super('Failed to read key: $key', cause: cause, stackTrace: stackTrace);

  @override
  List<Object?> get props => [key, message, cause];
}

class StorageWriteFailure extends StorageFailure {
  final String key;
  const StorageWriteFailure(this.key, {Object? cause, StackTrace? stackTrace})
    : super('Failed to write key: $key', cause: cause, stackTrace: stackTrace);

  @override
  List<Object?> get props => [key, message, cause];
}

class StorageResetFailure extends StorageFailure {
  const StorageResetFailure(super.message, {super.cause, super.stackTrace});
}

// ---------------------------------------------------------------------------
// Network Failures
// ---------------------------------------------------------------------------

sealed class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

class NoInternetFailure extends NetworkFailure {
  const NoInternetFailure({
    String message = 'No internet connection available',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

class NetworkTimeoutFailure extends NetworkFailure {
  const NetworkTimeoutFailure({
    String message = 'Network connection timed out',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

class ServerFailure extends NetworkFailure {
  final int? statusCode;
  const ServerFailure(
    this.statusCode,
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [statusCode, message, cause];
}

// ---------------------------------------------------------------------------
// TTS Failures
// ---------------------------------------------------------------------------

sealed class TtsFailure extends Failure {
  const TtsFailure(super.message, {super.cause, super.stackTrace});
}

class TtsModelNotFoundFailure extends TtsFailure {
  final String modelId;
  const TtsModelNotFoundFailure(
    this.modelId, {
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
         'TTS Model "$modelId" was not found',
         cause: cause,
         stackTrace: stackTrace,
       );

  @override
  List<Object?> get props => [modelId, message, cause];
}

class TtsDownloadFailure extends TtsFailure {
  final String modelId;
  const TtsDownloadFailure(
    this.modelId,
    String message, {
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);

  @override
  List<Object?> get props => [modelId, message, cause];
}

class TtsSynthesisFailure extends TtsFailure {
  const TtsSynthesisFailure(super.message, {super.cause, super.stackTrace});
}

class TtsWorkerFailure extends TtsFailure {
  const TtsWorkerFailure(super.message, {super.cause, super.stackTrace});
}

// ---------------------------------------------------------------------------
// Audio Failures
// ---------------------------------------------------------------------------

sealed class AudioFailure extends Failure {
  const AudioFailure(super.message, {super.cause, super.stackTrace});
}

class AudioPlaybackFailure extends AudioFailure {
  const AudioPlaybackFailure(super.message, {super.cause, super.stackTrace});
}

class AudioDeviceFailure extends AudioFailure {
  const AudioDeviceFailure(super.message, {super.cause, super.stackTrace});
}

// ---------------------------------------------------------------------------
// Permission Failures
// ---------------------------------------------------------------------------

sealed class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause, super.stackTrace});
}

class StoragePermissionDeniedFailure extends PermissionFailure {
  const StoragePermissionDeniedFailure({
    String message = 'Storage access permission was denied',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

class NotificationPermissionDeniedFailure extends PermissionFailure {
  const NotificationPermissionDeniedFailure({
    String message = 'Notification permission was denied',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

// ---------------------------------------------------------------------------
// Fallback / Unexpected Failure
// ---------------------------------------------------------------------------

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}
