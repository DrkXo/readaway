import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Font scale and styling tokens inspired by Lumia Inspired Metro UI.
///
/// Metro typography is characterized by high contrast, oversized light headers,
/// bold numbers, and uppercase tracking labels, following Swiss graphic design principles.
abstract final class MetroTypography {
  /// Huge light header used for Panorama and Pivot views.
  static const TextStyle pivotTitle = TextStyle(
    fontSize: 54,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.2,
    height: 1.05,
  );

  /// Section pivot item label (active / selected).
  static const TextStyle pivotItemActive = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    height: 1.15,
  );

  /// Section pivot item label (inactive).
  static const TextStyle pivotItemInactive = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.4,
    height: 1.2,
  );

  /// Section pivot item label (default fallback).
  static const TextStyle pivotItem = pivotItemActive;

  /// Bottom bar action label (e.g. "open", "add").
  static const TextStyle bottomAction = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.2,
  );

  /// Title inside a Metro Tile.
  static const TextStyle tileTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// Subtitle or secondary detail inside a Metro Tile.
  static const TextStyle tileSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  /// Large numerical readout on a stat or live tile (e.g., "85%", "24").
  static const TextStyle tileNumber = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.0,
  );

  /// Tiny uppercase tag / badge text with pronounced tracking.
  static const TextStyle tag = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  /// Small label positioned beneath an Application Bar icon.
  static const TextStyle appBarLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}

/// Convenience typography component adhering to Metro UI hierarchy.
class MetroText extends StatelessWidget {
  const MetroText.pivotTitle(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : style = MetroTypography.pivotTitle,
       isActive = true,
       isUppercase = false;

  const MetroText.pivotItem(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.isActive = true,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : style = MetroTypography.pivotItem,
       isUppercase = false;

  const MetroText.tileTitle(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  }) : style = MetroTypography.tileTitle,
       isActive = true,
       isUppercase = false;

  const MetroText.tileSubtitle(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : style = MetroTypography.tileSubtitle,
       isActive = true,
       isUppercase = false;

  const MetroText.tileNumber(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.maxLines = 1,
    this.overflow = TextOverflow.clip,
  }) : style = MetroTypography.tileNumber,
       isActive = true,
       isUppercase = false;

  const MetroText.tag(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : style = MetroTypography.tag,
       isActive = true,
       isUppercase = true;

  const MetroText.appBarLabel(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : style = MetroTypography.appBarLabel,
       isActive = true,
       isUppercase = false;

  const MetroText.bottomAction(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : style = MetroTypography.bottomAction,
       isActive = true,
       isUppercase = false;

  final String text;
  final TextStyle style;
  final Color? color;
  final double? fontSize;
  final bool isActive;
  final bool isUppercase;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final defaultColor = isActive
        ? appColors.readerForeground
        : appColors.readerForeground.withValues(alpha: 0.45);

    final displayText = isUppercase ? text.toUpperCase() : text;

    final resolvedStyle =
        (style == MetroTypography.pivotItem ||
            style == MetroTypography.pivotItemActive ||
            style == MetroTypography.pivotItemInactive)
        ? (isActive
              ? MetroTypography.pivotItemActive
              : MetroTypography.pivotItemInactive)
        : style;

    return Text(
      displayText,
      maxLines: maxLines,
      overflow: overflow,
      style: resolvedStyle.copyWith(
        color: color ?? defaultColor,
        fontSize: fontSize ?? resolvedStyle.fontSize,
      ),
    );
  }
}
