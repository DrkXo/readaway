part of '../core_widgets.dart';

/// Theme-aware slider.
///
/// Wraps Flutter's [Slider] with consistent track/thumb/overlay tokens derived
/// from [AppColors], plus optional label and value formatting. Use for font
/// size, brightness, TTS speed, and page seeking.
class AppSlider extends StatelessWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.valueLabel,
    this.onChangeStart,
    this.onChangeEnd,
    this.enabled = true,
    this.compact = false,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? valueLabel;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: compact ? 2 : 4,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: compact ? 6 : 8,
        ),
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: compact ? 14 : 18,
        ),
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.08),
        disabledActiveTrackColor: scheme.onSurface.withValues(alpha: 0.24),
        disabledInactiveTrackColor: scheme.onSurface.withValues(alpha: 0.08),
        disabledThumbColor: scheme.onSurface.withValues(alpha: 0.24),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: valueLabel,
        onChanged: enabled ? onChanged : null,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
      ),
    );

    if (label == null) return slider;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCaption(label!),
        const SizedBox(width: 12),
        Expanded(child: slider),
      ],
    );
  }
}
