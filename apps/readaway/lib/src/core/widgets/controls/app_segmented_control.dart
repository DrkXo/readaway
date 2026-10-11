part of '../core_widgets.dart';

/// A single selectable segment in an [AppSegmentedControl].
class AppSegment<T> {
  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? tooltip;
}

/// Theme-aware segmented control.
///
/// A single-choice control with an animated selected indicator, keyboard
/// focus support, and consistent theme tokens. Use for settings like font
/// size, theme, or alignment where a small set of mutually exclusive options
/// is shown.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MetroPivotControl<T>(
      value: value,
      enabled: enabled,
      expanded: true,
      size: MetroPivotControlSize.compact,
      style: MetroPivotControlStyle.flatTiles,
      items: [
        for (final s in segments)
          MetroPivotControlItem<T>(
            value: s.value,
            label: s.label,
            icon: s.icon,
            tooltip: s.tooltip,
          ),
      ],
      onChanged: onChanged,
    );
  }
}
