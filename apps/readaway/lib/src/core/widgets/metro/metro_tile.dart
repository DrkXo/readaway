import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/theme.dart';
import 'metro_pressable.dart';
import 'metro_typography.dart';

/// Semantic tile sizing in the Lumia Inspired Metro grid.
enum MetroTileSize {
  /// 1x1 compact tile.
  small,

  /// 2x2 standard square tile.
  medium,

  /// 4x2 / 2x1 wide landscape tile.
  wide,
}

/// Color theme role for a Metro Tile.
enum MetroTileColor {
  /// Vibrant accent-filled tile (Windows Phone primary tile).
  accent,

  /// Flat neutral surface-filled tile.
  surface,

  /// Canvas-colored or transparent tile.
  canvas,
}

/// A strictly flat, chromeless Live Tile inspired by Lumia Inspired.
///
/// Features:
/// - Zero elevation, zero shadows, zero border radius ([BorderRadius.zero]).
/// - Integrated 3D perspective tilt on touch via [MetroPressable].
/// - High-contrast typography and semantic slot layout (title, subtitle, badge, counter, icon).
class MetroTile extends StatelessWidget {
  const MetroTile({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.counter,
    this.icon,
    this.size = MetroTileSize.medium,
    this.colorRole = MetroTileColor.surface,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectMode = false,
    this.enableTilt = true,
    this.padding = const EdgeInsets.all(12.0),
  });

  /// Primary body content of the tile (e.g. book cover, graphic, custom layout).
  final Widget? child;

  /// Bottom-left pinned title.
  final String? title;

  /// Optional subtitle rendered beneath the title.
  final String? subtitle;

  /// Format badge or tag rendered in the top-left or bottom-right.
  final String? badge;

  /// Optional background color for the badge tag.
  final Color? badgeColor;

  /// Large numerical stat readout on the tile (e.g. "84%", "12").
  final String? counter;

  /// Iconic symbol displayed on the tile.
  final IconData? icon;

  /// Size tier in the Metro grid.
  final MetroTileSize size;

  /// Visual theme role.
  final MetroTileColor colorRole;

  /// Custom background color override.
  final Color? backgroundColor;

  /// Custom text and icon color override.
  final Color? foregroundColor;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Whether this tile is selected in selection mode.
  final bool isSelected;

  /// Whether the parent interface is in selection mode.
  final bool isSelectMode;

  /// Whether 3D perspective tilt is enabled.
  final bool enableTilt;

  /// Inner padding for tile contents.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    final Color effectiveBg =
        backgroundColor ??
        switch (colorRole) {
          MetroTileColor.accent => appColors.buttonBackground,
          MetroTileColor.surface => appColors.editorWidgetBackground,
          MetroTileColor.canvas => Colors.transparent,
        };

    final Color effectiveFg =
        foregroundColor ??
        switch (colorRole) {
          MetroTileColor.accent => appColors.buttonForeground,
          MetroTileColor.surface => appColors.readerForeground,
          MetroTileColor.canvas => appColors.readerForeground,
        };

    final tileBody = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        // Metro design law: zero rounded corners, zero shadow, zero outlines
        borderRadius: BorderRadius.zero,
        border: isSelected
            ? Border.all(
                color: appColors.buttonBackground,
                width: 3.0,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Main child or slot layout
          if (child != null)
            child!
          else
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null)
                    Icon(
                      icon,
                      size: size == MetroTileSize.small ? 22 : 32,
                      color: effectiveFg,
                    ),
                  if (counter != null) ...[
                    const Spacer(),
                    MetroText.tileNumber(
                      counter!,
                      color: effectiveFg,
                    ),
                  ],
                  if (title != null && counter == null) const Spacer(),
                  if (title != null) ...[
                    const SizedBox(height: 6),
                    MetroText.tileTitle(
                      title!,
                      color: effectiveFg,
                      maxLines: size == MetroTileSize.small ? 1 : 2,
                    ),
                  ],
                  if (subtitle != null && size != MetroTileSize.small) ...[
                    const SizedBox(height: 2),
                    MetroText.tileSubtitle(
                      subtitle!,
                      color: effectiveFg.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),

          // 2. Format / Status badge tag (top-left)
          if (badge != null && child != null)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                color:
                    badgeColor ??
                    appColors.readerBackground.withValues(alpha: 0.88),
                child: MetroText.tag(
                  badge!,
                  color: appColors.readerForeground,
                ),
              ),
            ),

          // 3. Selection mode indicator badge (top-right)
          if (isSelectMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? appColors.buttonBackground
                      : appColors.readerBackground.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: isSelected
                        ? appColors.buttonForeground
                        : appColors.borderSubtle,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        LucideIcons.check,
                        size: 16,
                        color: appColors.buttonForeground,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );

    if (!enableTilt) {
      if (onTap == null && onLongPress == null) return tileBody;
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: tileBody,
      );
    }

    return MetroPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: tileBody,
    );
  }
}
