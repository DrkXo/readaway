import 'package:flutter/material.dart';

/// Semantic types for toast and snackbar notifications.
enum ToastType {
  success,
  error,
  warning,
  info,
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
