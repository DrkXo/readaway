part of "../errors.dart";

/// Represents different types of API errors that can occur
enum CustomErrorTypes {
  // Network related errors
  noInternet('No internet connection available'),
  networkError('Network error occurred'),
  timeout('Request timed out'),
  connectionFailure('Failed to connect to the server'),

  jwtExpired('jwt expired'),

  // Server response errors
  serverError('Server error occurred'),
  maintenance('Server is under maintenance'),
  serviceUnavailable('Service is currently unavailable'),
  rateLimited('Too many requests, please try again later'),

  // Authentication/Authorization errors
  unauthorized('User is not authorized'),
  forbidden('Access to this resource is forbidden'),
  tokenExpired('Authentication token has expired'),
  invalidCredentials('Invalid username or password'),

  // Request errors
  badRequest('Bad request'),
  notFound('Resource not found'),
  methodNotAllowed('Method not allowed'),
  requestConflict('Request conflicts with current state'),

  // Data handling errors
  invalidFormat('Invalid data format'),
  parseFailure('Failed to parse response data'),
  validationError('Data validation failed'),
  missingRequiredField('Required field is missing'),

  // Storage errors
  storageReadFailure('Failed to read from storage'),
  storageWriteFailure('Failed to write to storage'),
  storageDeleteFailure('Failed to delete from storage'),
  storageFull('Storage is full'),
  storageCorrupted('Storage data is corrupted'),

  // Business logic errors
  operationFailed('Operation failed'),
  invalidOperation('Invalid operation'),
  resourceLocked('Resource is locked or in use'),
  resourceExhausted('Resource limit exceeded'),

  // Generic/fallback errors
  unknown('Unknown error occurred'),
  notImplemented('Feature not implemented'),

  // Upload Error
  errorUploading('Error uploading file, please re-upload again');

  /// The default error message for this error type
  final String message;

  const CustomErrorTypes(this.message);
}

/// Exception thrown when API requests fail
///
/// Includes details about the error type, message, status code, and any associated data
class ApiException extends Equatable implements Exception {
  /// Human-readable error message
  final String message;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Type of API error that occurred
  final CustomErrorTypes errorType;

  /// Additional data related to the error (if any)
  final dynamic data;

  ApiException({
    String? message,
    this.statusCode,
    required this.errorType,
    this.data,
  }) : message = message ?? errorType.message;

  // @override
  // String toString() =>
  //     'ApiException: $message (Status: $statusCode, Type: $errorType)';

  @override
  String toString() => message;

  @override
  List<Object?> get props => [message, statusCode, errorType, data];

  @override
  bool get stringify => true;
}

class DataFormattingException extends Equatable implements Exception {
  /// Human-readable error message
  final String message;

  /// Source of the formatting error
  final String? source;

  /// Type of formatting error that occurred
  final CustomErrorTypes errorType;

  /// Raw data that caused the formatting issue
  final dynamic invalidData;

  /// Additional context information
  final Map<String, dynamic>? context;

  DataFormattingException({
    String? message,
    this.source,
    required this.errorType,
    this.invalidData,
    this.context,
  }) : message = message ?? errorType.message;

  @override
  String toString() => message;

  @override
  List<Object?> get props => [message, source, errorType, invalidData, context];

  @override
  bool get stringify => true;
}

class DataStorageException extends Equatable implements Exception {
  /// Human-readable error message
  final String message;

  /// Storage operation that failed (read, write, delete, etc.)
  final String? operation;

  /// Type of storage error that occurred
  final CustomErrorTypes errorType;

  /// Key or identifier of the data being accessed
  final String? dataKey;

  /// Technical details about the storage failure
  final dynamic errorDetails;

  /// Additional context information
  final Map<String, dynamic>? context;

  DataStorageException({
    String? message,
    this.operation,
    required this.errorType,
    this.dataKey,
    this.errorDetails,
    this.context,
  }) : message = message ?? errorType.message;

  @override
  String toString() => message;

  @override
  List<Object?> get props => [
    message,
    operation,
    errorType,
    dataKey,
    errorDetails,
    context,
  ];

  @override
  bool get stringify => true;
}

class NetworkException extends Equatable implements Exception {
  /// Human-readable error message
  final String message;

  /// Type of network error that occurred
  final CustomErrorTypes errorType;

  NetworkException({
    String? message,
    required this.errorType,
  }) : message = message ?? errorType.message;

  @override
  String toString() => message;

  @override
  List<Object?> get props => [message, errorType];

  @override
  bool get stringify => true;
}

class LookupException implements Exception {
  LookupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LookupNotFound extends LookupException {
  LookupNotFound(super.message);
}
