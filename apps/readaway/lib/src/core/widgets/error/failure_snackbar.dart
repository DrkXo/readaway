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
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.alertCircle,
                color: scheme.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                failure.message,
                style: TextStyle(
                  color: scheme.onSurface,
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
