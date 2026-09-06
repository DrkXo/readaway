import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../error/failures.dart';
import 'toast_types.dart';
import 'toast_widget.dart';

/// Top-level getter for quick, context-free access to [ToastService].
ToastService get toastService => GetIt.I.get<ToastService>();

/// Application-wide toast and snackbar notification service.
///
/// Fully decoupled from [BuildContext] through [scaffoldMessengerKey], allowing
/// invocations from BLoCs, repositories, asynchronous workers, or UI widgets.
@lazySingleton
class ToastService {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'app_toast_messenger');

  ScaffoldMessengerState? get _messenger => scaffoldMessengerKey.currentState;

  /// Dismisses the currently displayed snackbar immediately.
  void hideCurrent() {
    _messenger?.hideCurrentSnackBar();
  }

  /// Removes all queued and currently showing snackbars.
  void clear() {
    _messenger?.clearSnackBars();
  }

  /// Shows a standardized floating toast notification.
  void show({
    required String message,
    String? title,
    ToastType type = ToastType.info,
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(milliseconds: 3500),
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    final messenger = _messenger;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: duration,
        content: Center(
          child: ToastWidget(
            message: message,
            title: title,
            type: type,
            icon: icon,
            action: action,
            onDismiss: () => messenger.hideCurrentSnackBar(),
            showCloseButton: showCloseButton,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  /// Displays a success toast notification.
  void showSuccess(
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  /// Displays an error toast notification with optional retry action.
  void showError(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 5),
    ToastAction? action,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    VoidCallback? onTap,
    bool showCloseButton = true,
  }) {
    final effectiveAction = action ??
        (onRetry != null
            ? ToastAction(label: retryLabel, onPressed: onRetry)
            : null);

    show(
      message: message,
      title: title,
      type: ToastType.error,
      duration: duration,
      action: effectiveAction,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  /// Displays a warning toast notification.
  void showWarning(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  /// Displays an informational toast notification.
  void showInfo(
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  /// Convenience method for displaying errors driven by a domain [Failure].
  void showFailure(
    Failure failure, {
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    Duration duration = const Duration(seconds: 5),
    String? title,
  }) {
    showError(
      failure.message,
      title: title,
      duration: duration,
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }

  /// Displays a completely custom widget inside a floating snackbar.
  void showCustom({
    required Widget content,
    Duration duration = const Duration(seconds: 4),
    EdgeInsetsGeometry margin =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  }) {
    final messenger = _messenger;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: margin,
        duration: duration,
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Convenience extension on [BuildContext] for displaying toasts.
extension ToastContextExtension on BuildContext {
  /// Quick access to [ToastService].
  ToastService get toasts => toastService;

  void showToast({
    required String message,
    String? title,
    ToastType type = ToastType.info,
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(milliseconds: 3500),
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    toastService.show(
      message: message,
      title: title,
      type: type,
      icon: icon,
      action: action,
      duration: duration,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  void showSuccessToast(
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    toastService.showSuccess(
      message,
      title: title,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  void showErrorToast(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 5),
    ToastAction? action,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    VoidCallback? onTap,
    bool showCloseButton = true,
  }) {
    toastService.showError(
      message,
      title: title,
      duration: duration,
      action: action,
      onRetry: onRetry,
      retryLabel: retryLabel,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  void showWarningToast(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    toastService.showWarning(
      message,
      title: title,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  void showInfoToast(
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
  }) {
    toastService.showInfo(
      message,
      title: title,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
    );
  }

  void showFailureToast(
    Failure failure, {
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    Duration duration = const Duration(seconds: 5),
    String? title,
  }) {
    toastService.showFailure(
      failure,
      onRetry: onRetry,
      retryLabel: retryLabel,
      duration: duration,
      title: title,
    );
  }

  void hideToast() {
    toastService.hideCurrent();
  }
}
