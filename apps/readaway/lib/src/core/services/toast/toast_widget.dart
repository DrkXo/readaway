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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appColors = Theme.of(context).extension<AppColors>();
    final scheme = Theme.of(context).colorScheme;

    final (
      Color bg,
      Color border,
      Color accent,
      Color text,
      Color subtleText
    ) = switch (type) {
      ToastType.success => isDark
          ? (
              const Color(0xFF1B2C20),
              const Color(0xFF2E4D35),
              appColors?.success ?? const Color(0xFF7CD98A),
              const Color(0xFFE2F3E5),
              const Color(0xFFB5DCC0),
            )
          : (
              const Color(0xFFEEF7F0),
              const Color(0xFFC3E3C9),
              appColors?.success ?? const Color(0xFF2E6C38),
              const Color(0xFF193B20),
              const Color(0xFF335C3B),
            ),
      ToastType.error => isDark
          ? (
              const Color(0xFF321B1D),
              const Color(0xFF5A2C30),
              scheme.error,
              const Color(0xFFFFD7D9),
              const Color(0xFFE8ADB2),
            )
          : (
              const Color(0xFFFDF1F2),
              const Color(0xFFF6C7CC),
              scheme.error,
              const Color(0xFF5C1B20),
              const Color(0xFF8A2E36),
            ),
      ToastType.warning => isDark
          ? (
              const Color(0xFF2F2414),
              const Color(0xFF5A4321),
              appColors?.warning ?? const Color(0xFFFFBA38),
              const Color(0xFFFFECC7),
              const Color(0xFFE0C495),
            )
          : (
              const Color(0xFFFFF9EE),
              const Color(0xFFF4DDB0),
              appColors?.warning ?? const Color(0xFF8B5A00),
              const Color(0xFF4C3000),
              const Color(0xFF754B00),
            ),
      ToastType.info => isDark
          ? (
              const Color(0xFF1E242C),
              const Color(0xFF324050),
              scheme.tertiary,
              const Color(0xFFDCE6F2),
              const Color(0xFFB0C4D8),
            )
          : (
              const Color(0xFFF0F5FA),
              const Color(0xFFC8DAEC),
              scheme.tertiary,
              const Color(0xFF1B354C),
              const Color(0xFF3B5B78),
            ),
    };

    final effectiveIcon = icon ?? _defaultIcon(type);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
              boxShadow: appColors?.shadowMd ??
                  const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
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
