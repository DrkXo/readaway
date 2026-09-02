part of '../core_widgets.dart';

/// Size tiers for [AppIconButton], mapped to consistent icon + hit-area sizes.
enum AppIconButtonSize {
  /// Small inline control (icon 16, hit area 32).
  small,

  /// Standard control (icon 20, hit area 40).
  medium,

  /// Large control (icon 24, hit area 48).
  large;

  double get iconSize => switch (this) {
    AppIconButtonSize.small => 16,
    AppIconButtonSize.medium => 20,
    AppIconButtonSize.large => 24,
  };

  /// Minimum hit area. On touch platforms the effective hit area is expanded
  /// to at least 44 logical pixels via [AppIconButton]'s padding.
  double get hitArea => switch (this) {
    AppIconButtonSize.small => 32,
    AppIconButtonSize.medium => 40,
    AppIconButtonSize.large => 48,
  };
}

/// Theme-aware icon button.
///
/// Provides consistent sizing, tooltip, pressed feedback (opacity + subtle
/// scale — no layout shift), and accessibility semantics. On touch platforms
/// the hit area is expanded to at least 44pt. Prefer this over raw
/// `IconButton` for new UI.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = AppIconButtonSize.medium,
    this.color,
    this.selected = false,
    this.selectedColor,
    this.semanticLabel,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final Color? color;
  final bool selected;
  final Color? selectedColor;
  final String? semanticLabel;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    final baseColor =
        widget.color ??
        (widget.selected
            ? (widget.selectedColor ?? scheme.primary)
            : scheme.onSurfaceVariant);
    final effectiveColor = enabled
        ? baseColor
        : scheme.onSurface.withValues(alpha: 0.38);

    // Expand hit area to >= 44pt on touch platforms.
    final isTouch =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final minHit = isTouch ? 44.0 : widget.size.hitArea.toDouble();
    final pad = ((minHit - widget.size.iconSize) / 2).clamp(0.0, 12.0);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel ?? widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _pressed ? 0.7 : 1.0,
              duration: const Duration(milliseconds: 90),
              child: Container(
                padding: EdgeInsets.all(pad),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? scheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  size: widget.size.iconSize,
                  color: effectiveColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
