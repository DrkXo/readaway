import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Header row for a page inside the settings sheet:
/// Features authentic Windows Phone / Lumia two-line horizon typography:
/// uppercase category tag (e.g. `SETTINGS`), grand light lower-case title (`34pt`, `w300`),
/// and sleek touch-reactive leading/trailing actions with zero dividing lines.
class SettingsSheetHeader extends StatelessWidget {
  const SettingsSheetHeader({
    super.key,
    required this.title,
    this.category = 'settings',
    this.leading,
    this.trailing,
  });

  final String title;
  final String? category;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null)
            Text(
              category!.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: appColors.readerForeground.withValues(alpha: 0.5),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title.toLowerCase(),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1.0,
                    height: 1.15,
                    color: appColors.readerForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

/// Back arrow for a sub-page of the settings sheet.
///
/// Features authentic Metro touch interaction with tilt feedback and clean iconography.
class SettingsSheetBackButton extends StatelessWidget {
  const SettingsSheetBackButton({
    super.key,
    this.useText = false,
  });

  final bool useText;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    void handlePop() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }

    return MetroPressable(
      onTap: handlePop,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.arrowLeft,
              size: 24,
              color: appColors.readerForeground,
            ),
            if (useText) ...[
              const SizedBox(width: 6),
              Text(
                'back',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: appColors.readerForeground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Close button for the settings page.
///
/// Pops the enclosing navigator or root navigator when dismissed.
class SettingsSheetCloseButton extends StatelessWidget {
  const SettingsSheetCloseButton({
    super.key,
    this.useText = false,
  });

  final bool useText;

  @override
  Widget build(BuildContext context) {
    void handlePop() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }

    if (useText) {
      final appColors = context.appColors;
      return MetroPressable(
        onTap: handlePop,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            'close',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: appColors.readerForeground.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(LucideIcons.x),
      tooltip: 'Close settings',
      onPressed: handlePop,
    );
  }
}
