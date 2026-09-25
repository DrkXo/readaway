import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../error/failures.dart';
import 'toast_types.dart';
import 'toast_widget.dart';

/// Top-level getter for quick, context-free access to [ToastService].
ToastService get toastService => GetIt.I.get<ToastService>();

/// Application-wide toast notification service.
///
/// Fully decoupled from [BuildContext] through an overlay host architecture, allowing
/// toasts to appear cleanly above all routes, dialogs, modal sheets, and full-screen views.
@lazySingleton
class ToastService extends ChangeNotifier {
  /// Backward-compatible key for any legacy widgets that reference it.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'app_toast_messenger');

  final ValueNotifier<ToastEntry?> _currentToastNotifier =
      ValueNotifier<ToastEntry?>(null);

  /// Notifier exposing the currently active toast entry for the overlay host.
  ValueNotifier<ToastEntry?> get currentToastNotifier => _currentToastNotifier;

  /// The currently active toast entry, or null if no toast is displayed.
  ToastEntry? get currentToast => _currentToastNotifier.value;

  int _toastCounter = 0;

  /// Dismisses the currently displayed toast immediately.
  void hideCurrent() {
    _currentToastNotifier.value = null;
    notifyListeners();
  }

  /// Removes all queued and currently showing toasts.
  void clear() {
    _currentToastNotifier.value = null;
    notifyListeners();
  }

  /// Shows a standardized floating toast notification over all screens, dialogs, and modals.
  void show({
    required String message,
    String? title,
    ToastType type = ToastType.info,
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(milliseconds: 3500),
    VoidCallback? onTap,
    bool showCloseButton = false,
    ToastPosition position = ToastPosition.bottom,
    bool dismissOnSwipe = true,
  }) {
    final toastId =
        'toast_${++_toastCounter}_${DateTime.now().microsecondsSinceEpoch}';

    final entry = ToastEntry(
      id: toastId,
      duration: duration,
      position: position,
      dismissOnSwipe: dismissOnSwipe,
      content: ToastWidget(
        message: message,
        title: title,
        type: type,
        icon: icon,
        action: action,
        onDismiss: () => _dismissEntry(toastId),
        showCloseButton: showCloseButton,
        onTap: onTap,
      ),
    );

    _currentToastNotifier.value = entry;
    notifyListeners();
  }

  void _dismissEntry(String toastId) {
    if (_currentToastNotifier.value?.id == toastId) {
      _currentToastNotifier.value = null;
      notifyListeners();
    }
  }

  /// Displays a success toast notification.
  void showSuccess(
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
    ToastPosition position = ToastPosition.bottom,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
      position: position,
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
    ToastPosition position = ToastPosition.bottom,
  }) {
    final effectiveAction =
        action ??
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
      position: position,
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
    ToastPosition position = ToastPosition.bottom,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
      position: position,
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
    ToastPosition position = ToastPosition.bottom,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
      position: position,
    );
  }

  /// Convenience method for displaying errors driven by a domain [Failure].
  void showFailure(
    Failure failure, {
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    Duration duration = const Duration(seconds: 5),
    String? title,
    ToastPosition position = ToastPosition.bottom,
  }) {
    showError(
      failure.message,
      title: title,
      duration: duration,
      onRetry: onRetry,
      retryLabel: retryLabel,
      position: position,
    );
  }

  /// Displays a completely custom widget inside the floating toast overlay.
  void showCustom({
    required Widget content,
    Duration duration = const Duration(seconds: 4),
    ToastPosition position = ToastPosition.bottom,
    bool dismissOnSwipe = true,
  }) {
    final toastId =
        'custom_toast_${++_toastCounter}_${DateTime.now().microsecondsSinceEpoch}';

    final entry = ToastEntry(
      id: toastId,
      duration: duration,
      position: position,
      dismissOnSwipe: dismissOnSwipe,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: content,
      ),
    );

    _currentToastNotifier.value = entry;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentToastNotifier.dispose();
    super.dispose();
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
    ToastPosition position = ToastPosition.bottom,
    bool dismissOnSwipe = true,
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
      position: position,
      dismissOnSwipe: dismissOnSwipe,
    );
  }

  void showSuccessToast(
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
    ToastPosition position = ToastPosition.bottom,
  }) {
    toastService.showSuccess(
      message,
      title: title,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
      position: position,
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
    ToastPosition position = ToastPosition.bottom,
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
      position: position,
    );
  }

  void showWarningToast(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
    ToastPosition position = ToastPosition.bottom,
  }) {
    toastService.showWarning(
      message,
      title: title,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
      position: position,
    );
  }

  void showInfoToast(
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    ToastAction? action,
    VoidCallback? onTap,
    bool showCloseButton = false,
    ToastPosition position = ToastPosition.bottom,
  }) {
    toastService.showInfo(
      message,
      title: title,
      duration: duration,
      action: action,
      onTap: onTap,
      showCloseButton: showCloseButton,
      position: position,
    );
  }

  void showFailureToast(
    Failure failure, {
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    Duration duration = const Duration(seconds: 5),
    String? title,
    ToastPosition position = ToastPosition.bottom,
  }) {
    toastService.showFailure(
      failure,
      onRetry: onRetry,
      retryLabel: retryLabel,
      duration: duration,
      title: title,
      position: position,
    );
  }

  void hideToast() {
    toastService.hideCurrent();
  }
}
