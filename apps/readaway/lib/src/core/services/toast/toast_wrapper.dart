import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'toast_service.dart';

/// An [InheritedWidget] providing descendant access to [ToastService].
class ToastScope extends InheritedWidget {
  final ToastService service;

  const ToastScope({
    super.key,
    required this.service,
    required super.child,
  });

  /// Retrieves the nearest [ToastService], or falls back to [GetIt.I].
  static ToastService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ToastScope>();
    return scope?.service ?? GetIt.I.get<ToastService>();
  }

  /// Retrieves the nearest [ToastService], or returns `null` if unmounted.
  static ToastService? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ToastScope>();
    return scope?.service;
  }

  @override
  bool updateShouldNotify(ToastScope oldWidget) => service != oldWidget.service;
}

/// A wrapper widget that embeds [ToastScope] around the application widget tree.
class ToastWrapper extends StatelessWidget {
  final Widget child;
  final ToastService? service;

  const ToastWrapper({
    super.key,
    required this.child,
    this.service,
  });

  /// Factory helper for use directly inside [MaterialApp.builder].
  static Widget builder(BuildContext context, Widget? child) {
    return ToastWrapper(
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveService = service ??
        (GetIt.I.isRegistered<ToastService>()
            ? GetIt.I.get<ToastService>()
            : null);

    if (effectiveService == null) {
      return child;
    }

    return ToastScope(
      service: effectiveService,
      child: child,
    );
  }
}
