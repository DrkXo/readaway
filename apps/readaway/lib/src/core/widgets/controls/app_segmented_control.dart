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
    final scheme = Theme.of(context).colorScheme;
    final selectedIndex = segments.indexWhere((s) => s.value == value);

    return Semantics(
      container: true,
      label: 'Segmented control',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < segments.length; i++)
              _buildSegment(context, i, selectedIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(BuildContext context, int index, int selectedIndex) {
    final scheme = Theme.of(context).colorScheme;
    final segment = segments[index];
    final isSelected = index == selectedIndex;
    final isEnabled = enabled && !isSelected;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: segment.tooltip ?? segment.label,
        child: Tooltip(
          message: segment.tooltip ?? segment.label,
          child: InkWell(
            onTap: isEnabled ? () => onChanged(segment.value) : null,
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected ? context.appColors.shadowSm : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (segment.icon != null) ...[
                    Icon(
                      segment.icon,
                      size: 16,
                      color: isSelected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    segment.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
