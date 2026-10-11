import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/theme.dart';
import 'metro_pressable.dart';
import 'metro_typography.dart';

/// An action item button rendered on the [MetroAppBar].
class MetroAppBarAction {
  const MetroAppBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });

  /// The vector icon for this action.
  final IconData icon;

  /// Short lowercase label below the circular icon (e.g. "add", "search", "open").
  final String label;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Whether this action uses the vibrant theme accent fill.
  final bool isAccent;
}

/// A secondary menu item displayed in the expanded Application Bar menu.
class MetroAppBarMenuItem {
  const MetroAppBarMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
  });

  /// Menu text (e.g. "sort by title", "select books", "settings").
  final String label;

  /// Tap callback.
  final VoidCallback onTap;

  /// Optional icon.
  final IconData? icon;
}

/// Anchored at the bottom of the screen with circular flat icon buttons,
/// lowercase labels, and an ellipsis button (`...`) that expands secondary actions.
class MetroAppBar extends StatelessWidget {
  const MetroAppBar({
    super.key,
    required this.actions,
    this.menuItems,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Primary circular actions (typically 2 to 4).
  final List<MetroAppBarAction> actions;

  /// Secondary menu items revealed by the ellipsis (`...`) button.
  final List<MetroAppBarMenuItem>? menuItems;

  /// Background color override (defaults to theme bottombar background).
  final Color? backgroundColor;

  /// Text and icon color override.
  final Color? foregroundColor;

  void _openMenu(BuildContext context) {
    if (menuItems == null || menuItems!.isEmpty) return;

    final appColors = context.appColors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appColors.readerBackground,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in menuItems!)
                  MetroPressable(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      item.onTap();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          if (item.icon != null) ...[
                            Icon(
                              item.icon,
                              size: 18,
                              color: appColors.readerForeground,
                            ),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Text(
                              item.label.toLowerCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: appColors.readerForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final bg = backgroundColor ?? appColors.bottombarBackground;
    final fg = foregroundColor ?? appColors.bottombarForeground;
    final hasMenu = menuItems != null && menuItems!.isNotEmpty;

    return Container(
      color: bg,
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final action in actions)
            Flexible(
              child: MetroPressable(
                onTap: action.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: action.isAccent
                              ? appColors.buttonBackground
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: action.isAccent
                                ? appColors.buttonBackground
                                : fg,
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            action.icon,
                            size: 20,
                            color: action.isAccent
                                ? appColors.buttonForeground
                                : fg,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MetroText.appBarLabel(
                        action.label.toLowerCase(),
                        color: fg,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasMenu)
            Flexible(
              child: MetroPressable(
                onTap: () => _openMenu(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: fg, width: 2.0),
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.ellipsis,
                            size: 20,
                            color: fg,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MetroText.appBarLabel(
                        'more',
                        color: fg,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
