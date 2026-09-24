import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Represents the outcome of an operation that can either succeed with [T] or fail with [Failure].
sealed class Result<T> extends Equatable {
  const Result();

  /// Folds the result by applying [onFailure] if this is a [Failed] or [onSuccess] if this is a [Success].
  R fold<R>(
    R Function(Failure error) onFailure,
    R Function(T data) onSuccess,
  ) => switch (this) {
    Success(:final data) => onSuccess(data),
    Failed(:final error) => onFailure(error),
  };

  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this is a [Failed].
  bool get isFailure => this is Failed<T>;

  /// Returns data [T] when this is [Success], or `null` when [Failed].
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failed() => null,
  };

  /// Returns the [Failure] when this is [Failed], or `null` when [Success].
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Failed(:final error) => error,
  };

  @override
  bool? get stringify => true;
}

/// Represents a successful result containing [data].
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

/// Represents a failed result containing a domain [error].
final class Failed<T> extends Result<T> {
  final Failure error;
  const Failed(this.error);

  @override
  List<Object?> get props => [error];
}

/// Wraps an asynchronous action, capturing exceptions and converting them to [Failed].
Future<Result<T>> guard<T>(
  Future<T> Function() action, {
  required Failure Function(Object error, StackTrace st) onError,
}) async {
  try {
    final data = await action();
    return Success(data);
  } catch (e, st) {
    return Failed(onError(e, st));
  }
}

/// Wraps a synchronous action, capturing exceptions and converting them to [Failed].
Result<T> guardSync<T>(
  T Function() action, {
  required Failure Function(Object error, StackTrace st) onError,
}) {
  try {
    final data = action();
    return Success(data);
  } catch (e, st) {
    return Failed(onError(e, st));
  }
}

/// Extension for chaining async operations on [Result].
extension ResultChain<T> on Result<T> {
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) next,
  ) async => switch (this) {
    Success(:final data) => next(data),
    Failed(:final error) => Failed(error),
  };
}
