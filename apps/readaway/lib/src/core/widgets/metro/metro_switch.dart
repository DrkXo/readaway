import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'metro_pressable.dart';

/// Size tier for a [MetroSwitch].
enum MetroSwitchSize {
  /// Standard sizing (~46x24px) for settings lists, dialogs, and primary forms.
  normal,

  /// Compact sizing (~38x20px) for tight toolbars and dense inline controls.
  compact,
}

/// Authentic Lumia / Windows Phone Metro Toggle Switch.
///
/// A production-grade, reusable replacement for Material [Switch] following
/// authentic Metro / Modern UI design principles:
/// - Strictly rectangular geometry with zero border radius (`BorderRadius.zero`).
/// - 2px high-contrast perimeter border.
/// - Inactive (Off): Transparent/surface background, muted perimeter border,
///   solid rectangular thumb parked on the left.
/// - Active (On): Solid accent track (`appColors.buttonBackground`),
///   contrast rectangular thumb (`appColors.buttonForeground`) parked on the right.
/// - Fluid easeOutCubic sliding animation.
/// - 3D perspective tilt on touch powered by [MetroPressable].
/// - Optional lowercase state label (e.g. `'on'` / `'off'`).
/// - Full accessibility and [Semantics] support.
class MetroSwitch extends StatelessWidget {
  const MetroSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showStateLabel = false,
    this.onLabel = 'on',
    this.offLabel = 'off',
    this.size = MetroSwitchSize.normal,
    this.activeColor,
    this.inactiveColor,
  });

  /// Whether the switch is checked/on.
  final bool value;

  /// Called when the switch is toggled. If null or [enabled] is false,
  /// the switch is disabled and non-interactive.
  final ValueChanged<bool>? onChanged;

  /// Whether user interaction is enabled.
  final bool enabled;

  /// Whether to render a lowercase state label beside the switch.
  final bool showStateLabel;

  /// Text for the active state (defaults to `'on'`).
  final String onLabel;

  /// Text for the inactive state (defaults to `'off'`).
  final String offLabel;

  /// Size tier (normal vs compact).
  final MetroSwitchSize size;

  /// Override color for the active track and border.
  final Color? activeColor;

  /// Override color for the inactive border and thumb.
  final Color? inactiveColor;

  bool get _isInteractive => enabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    final isCompact = size == MetroSwitchSize.compact;
    final trackWidth = isCompact ? 38.0 : 46.0;
    final trackHeight = isCompact ? 20.0 : 24.0;
    const borderWidth = 2.0;
    final thumbWidth = isCompact ? 10.0 : 12.0;
    final innerWidth = trackWidth - 2 * borderWidth;
    final innerHeight = trackHeight - 2 * borderWidth;
    final maxLeft = innerWidth - thumbWidth;

    final effectiveActiveColor = activeColor ?? appColors.buttonBackground;
    final effectiveInactiveColor =
        inactiveColor ?? appColors.readerForeground.withValues(alpha: 0.45);

    final currentTrackColor = value
        ? effectiveActiveColor
        : appColors.readerForeground.withValues(alpha: 0.02);

    final currentBorderColor = value
        ? effectiveActiveColor
        : effectiveInactiveColor;

    final currentThumbColor = value
        ? appColors.buttonForeground
        : effectiveInactiveColor;

    final switchBox = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: trackWidth,
      height: trackHeight,
      decoration: BoxDecoration(
        color: currentTrackColor,
        border: Border.all(
          color: currentBorderColor,
          width: borderWidth,
        ),
      ),
      child: SizedBox(
        width: innerWidth,
        height: innerHeight,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: 0,
              left: value ? maxLeft : 0,
              width: thumbWidth,
              child: Container(
                color: currentThumbColor,
              ),
            ),
          ],
        ),
      ),
    );

    Widget content = switchBox;

    if (showStateLabel) {
      final labelText = (value ? onLabel : offLabel).toLowerCase();
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            labelText,
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: _isInteractive
                  ? (value ? effectiveActiveColor : effectiveInactiveColor)
                  : effectiveInactiveColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          switchBox,
        ],
      );
    }

    return Semantics(
      toggled: value,
      enabled: _isInteractive,
      button: true,
      label: showStateLabel ? (value ? onLabel : offLabel) : null,
      child: MetroPressable(
        enabled: _isInteractive,
        onTap: _isInteractive ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: _isInteractive ? 1.0 : 0.38,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: content,
          ),
        ),
      ),
    );
  }
}
