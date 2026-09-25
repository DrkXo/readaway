import 'package:flutter/material.dart';

/// Semantic types for toast and snackbar notifications.
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Screen positioning for toast notifications.
enum ToastPosition {
  top,
  bottom,
}

/// Action definition for toasts with an interactive button.
class ToastAction {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;

  const ToastAction({
    required this.label,
    required this.onPressed,
    this.textColor,
  });
}

/// Model representing an active toast notification displayed by the overlay.
class ToastEntry {
  final String id;
  final Widget content;
  final Duration duration;
  final ToastPosition position;
  final VoidCallback? onDismiss;
  final bool dismissOnSwipe;

  const ToastEntry({
    required this.id,
    required this.content,
    this.duration = const Duration(milliseconds: 3500),
    this.position = ToastPosition.bottom,
    this.onDismiss,
    this.dismissOnSwipe = true,
  });
}

