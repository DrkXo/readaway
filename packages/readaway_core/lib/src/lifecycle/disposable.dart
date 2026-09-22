import 'dart:async';
import 'package:meta/meta.dart';
import '../errors/document_exception.dart';

/// Interface for objects that hold resources requiring explicit disposal.
abstract interface class Disposable {
  /// Whether this object has already been disposed.
  bool get isDisposed;

  /// Releases all resources, caches, and listeners held by this object.
  FutureOr<void> dispose();
}

/// A mixin that provides standard disposal lifecycle tracking and guards.
mixin DisposableMixin implements Disposable {
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  /// Throws a [DocumentDisposedException] if this object has already been disposed.
  @protected
  void checkNotDisposed([String? operation]) {
    if (_isDisposed) {
      final op = operation != null ? ' ($operation)' : '';
      throw DocumentDisposedException('Cannot use a disposed $runtimeType$op');
    }
  }

  @override
  @mustCallSuper
  FutureOr<void> dispose() {
    _isDisposed = true;
  }
}
