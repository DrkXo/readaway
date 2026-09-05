import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../error/failures.dart';

/// Extension on [BuildContext] to show a standardized [SnackBar] driven by a [Failure].
extension FailureSnackBarExtension on BuildContext {
  void showFailureSnackBar(
    Failure failure, {
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final scheme = Theme.of(this).colorScheme;

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.errorContainer,
        content: Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: scheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                failure.message,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: retryLabel,
                textColor: scheme.error,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
