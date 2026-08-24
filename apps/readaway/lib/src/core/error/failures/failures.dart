import 'package:equatable/equatable.dart';

/// Base Failure class for domain layer failures
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server related failures
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Network related failures (no internet connection)
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Cache related failures (local storage issues)
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Input validation failures (invalid input data)
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Authentication related failures (login/auth issues)
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Permission related failures (user lacks permission)
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

/// Unexpected failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}

class DataParsingFailure extends Failure {
  const DataParsingFailure({required super.message, super.code});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}
