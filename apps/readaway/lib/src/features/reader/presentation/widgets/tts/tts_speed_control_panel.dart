import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// An interactive, accessible playback speed controller with:
/// 1. Precision slider (0.5× – 2.5×) with 0.05× step divisions.
/// 2. Minus & plus fine-tuning steppers for effortless single-handed micro-adjustments.
/// 3. Instant 1-tap quick preset chips (0.75×, 1.0×, 1.25×, 1.5×, 1.75×, 2.0×).
/// 4. One-touch "Reset to 1.0×" action.
class TtsSpeedControlPanel extends StatelessWidget {
  const TtsSpeedControlPanel({
    required this.rate,
    required this.onRateChanged,
    this.onClose,
    super.key,
  });

  /// Current playback rate multiplier (e.g. 1.0, 1.25).
  final double rate;

  /// Callback when user changes the rate via slider, steppers, or preset chips.
  final ValueChanged<double> onRateChanged;

  /// Optional callback to close or collapse the panel.
  final VoidCallback? onClose;

  static const double minRate = 0.5;
  static const double maxRate = 2.5;
  static const double step = 0.05;
  static const List<double> presetSpeeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  static String formatRate(double r) {
    final s = r.toStringAsFixed(2);
    if (s.endsWith('0')) {
      return '${r.toStringAsFixed(1)}×';
    }
    return '$s×';
  }

  void _stepRate(double delta) {
    final next = (rate + delta).clamp(minRate, maxRate);
    final rounded = (next / step).round() * step;
    onRateChanged(double.parse(rounded.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDefaultRate = (rate - 1.0).abs() < 0.01;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Label, Live Readout & Close / Reset
          Row(
            children: [
              Icon(
                LucideIcons.gauge,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Playback Speed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              // Current Speed Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatRate(rate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (!isDefaultRate) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reset to 1.0×',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () => onRateChanged(1.0),
                  icon: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (onClose != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Close speed settings',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: onClose,
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // 2. Stepper & Slider Row
          Row(
            children: [
              // Decrease Stepper Button (>=44pt touch target)
              IconButton(
                icon: const Icon(LucideIcons.minus, size: 18),
                tooltip: 'Decrease speed (-0.05×)',
                style: IconButton.styleFrom(
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  foregroundColor: scheme.onSurface,
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(44, 44),
                ),
                onPressed: rate > minRate ? () => _stepRate(-step) : null,
              ),

              // Continuous Slider with 0.05 step divisions
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.surfaceContainerHighest,
                    thumbColor: scheme.primary,
                    valueIndicatorColor: scheme.primary,
                    valueIndicatorTextStyle: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Slider(
                    value: rate.clamp(minRate, maxRate),
                    min: minRate,
                    max: maxRate,
                    divisions: ((maxRate - minRate) / step).round(),
                    label: formatRate(rate),
                    onChanged: (val) {
                      final rounded = (val / step).round() * step;
                      onRateChanged(
                        double.parse(rounded.toStringAsFixed(2)),
                      );
                    },
                  ),
                ),
              ),

              // Increase Stepper Button (>=44pt touch target)
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 18),
                tooltip: 'Increase speed (+0.05×)',
                style: IconButton.styleFrom(
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  foregroundColor: scheme.onSurface,
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(44, 44),
                ),
                onPressed: rate < maxRate ? () => _stepRate(step) : null,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. One-Tap Preset Chips Row with comfortable touch targets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: presetSpeeds.map((preset) {
                final isSelected = (rate - preset).abs() < 0.02;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onRateChanged(preset),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 38, minWidth: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        formatRate(preset),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}
