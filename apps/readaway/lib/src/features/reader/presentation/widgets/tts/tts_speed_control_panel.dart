import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';

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
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final isDefaultRate = (rate - 1.0).abs() < 0.01;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: appColors.panelBackground,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: appColors.panelBorder,
          width: 1.0,
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
                color: appColors.buttonBackground,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'playback speed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.topbarForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              // Current Speed Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: appColors.buttonBackground,
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  formatRate(rate),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: appColors.buttonForeground,
                  ),
                ),
              ),
              if (!isDefaultRate) ...[
                const SizedBox(width: 8),
                MetroPressable(
                  onTap: () => onRateChanged(1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: appColors.panelBorder,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      'reset',
                      style: TextStyle(
                        fontSize: 12,
                        color: appColors.buttonBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              if (onClose != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Close speed settings',
                  child: Semantics(
                    label: 'Close speed settings',
                    button: true,
                    child: MetroPressable(
                      onTap: onClose,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: appColors.topbarForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // 2. Stepper & Slider Row
          Row(
            children: [
              // Decrease Stepper Button
              Tooltip(
                message: 'Decrease speed (-0.05×)',
                child: Semantics(
                  label: 'Decrease speed (-0.05×)',
                  button: true,
                  child: MetroPressable(
                    onTap: rate > minRate ? () => _stepRate(-step) : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: appColors.panelBorder,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.minus,
                          size: 18,
                          color: rate > minRate
                              ? appColors.topbarForeground
                              : appColors.topbarForeground.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Continuous Slider with 0.05 step divisions
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const MetroSliderThumbShape(
                      thumbRadius: 7,
                    ),
                    trackShape: const RectangularSliderTrackShape(),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: appColors.buttonBackground,
                    inactiveTrackColor: appColors.panelBorder,
                    thumbColor: appColors.buttonBackground,
                    valueIndicatorColor: appColors.buttonBackground,
                    valueIndicatorTextStyle: TextStyle(
                      color: appColors.buttonForeground,
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

              // Increase Stepper Button
              Tooltip(
                message: 'Increase speed (+0.05×)',
                child: Semantics(
                  label: 'Increase speed (+0.05×)',
                  button: true,
                  child: MetroPressable(
                    onTap: rate < maxRate ? () => _stepRate(step) : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: appColors.panelBorder,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.plus,
                          size: 18,
                          color: rate < maxRate
                              ? appColors.topbarForeground
                              : appColors.topbarForeground.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. One-Tap Preset Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: presetSpeeds
                  .map((preset) {
                    final isSelected = (rate - preset).abs() < 0.02;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Tooltip(
                        message: 'Set speed to ${formatRate(preset)}',
                        child: Semantics(
                          label: 'Set speed to ${formatRate(preset)}',
                          button: true,
                          child: MetroPressable(
                            onTap: () => onRateChanged(preset),
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 34,
                                minWidth: 44,
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? appColors.buttonBackground
                                    : appColors.panelBackground,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(
                                  color: isSelected
                                      ? appColors.buttonBackground
                                      : appColors.panelBorder,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                formatRate(preset),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? appColors.buttonForeground
                                      : appColors.topbarForeground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}
