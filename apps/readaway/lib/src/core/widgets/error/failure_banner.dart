import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../error/failures.dart';

/// An inline, compact error ribbon suitable for embedded cards, bottom sheets,
/// or toolbars where a full-page [FailureView] would be too disruptive.
class FailureBanner extends StatelessWidget {
  const FailureBanner({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry margin;

  IconData _iconFor(Failure failure) {
    return switch (failure) {
      DocumentFailure() => LucideIcons.fileWarning,
      StorageFailure() => LucideIcons.database,
      NetworkFailure() => LucideIcons.wifiOff,
      TtsFailure() => LucideIcons.speech,
      AudioFailure() => LucideIcons.volumeX,
      PermissionFailure() => LucideIcons.shieldAlert,
      _ => LucideIcons.alertCircle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _iconFor(failure),
            size: 20,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              failure.message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onErrorContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              tooltip: 'Retry',
              color: scheme.onErrorContainer,
              onPressed: onRetry,
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16),
              tooltip: 'Dismiss',
              color: scheme.onErrorContainer,
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
