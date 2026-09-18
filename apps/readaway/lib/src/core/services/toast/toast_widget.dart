import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/theme.dart';
import 'toast_types.dart';

/// A polished, accessible floating toast widget.
class ToastWidget extends StatelessWidget {
  final String message;
  final String? title;
  final ToastType type;
  final IconData? icon;
  final ToastAction? action;
  final VoidCallback? onDismiss;
  final bool showCloseButton;
  final VoidCallback? onTap;

  const ToastWidget({
    super.key,
    required this.message,
    this.title,
    this.type = ToastType.info,
    this.icon,
    this.action,
    this.onDismiss,
    this.showCloseButton = false,
    this.onTap,
  });

  IconData _defaultIcon(ToastType type) => switch (type) {
    ToastType.success => LucideIcons.circleCheck,
    ToastType.error => LucideIcons.alertCircle,
    ToastType.warning => LucideIcons.alertTriangle,
    ToastType.info => LucideIcons.info,
  };

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    final bg = appColors.notificationBackground;
    final border = appColors.notificationBorder;
    final text = appColors.notificationForeground;
    final subtleText = appColors.notificationForeground.withValues(alpha: 0.75);

    final Color accent = switch (type) {
      ToastType.success => appColors.success,
      ToastType.error => appColors.error,
      ToastType.warning => appColors.warning,
      ToastType.info => appColors.badgeBackground ?? appColors.scheme.primary,
    };

    final effectiveIcon = icon ?? _defaultIcon(type);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border, width: 1),
              boxShadow: appColors.shadowMd,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Semantic icon badge
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    effectiveIcon,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Content (Title + Message)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title!.trim().isNotEmpty) ...[
                        Text(
                          title!,
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        message,
                        style: TextStyle(
                          color: subtleText,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Optional Action Button
                if (action != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      action!.onPressed();
                      onDismiss?.call();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: action!.textColor ?? accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(44, 36),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(action!.label),
                  ),
                ],

                // Optional Close Button
                if (showCloseButton && action == null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    color: subtleText,
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    splashRadius: 18,
                    tooltip: 'Dismiss',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
