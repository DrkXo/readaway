import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// An interactive, accessible voice pitch controller with:
/// 1. Precision slider (0.5× – 2.0×) with 0.05× step divisions.
/// 2. Minus & plus fine-tuning steppers for effortless single-handed micro-adjustments.
/// 3. Instant 1-tap quick preset chips (0.75×, 0.9×, 1.0×, 1.1×, 1.25×, 1.5×).
/// 4. One-touch "Reset to 1.0×" action.
class TtsPitchControlPanel extends StatelessWidget {
  const TtsPitchControlPanel({
    required this.pitch,
    required this.onPitchChanged,
    this.onClose,
    super.key,
  });

  /// Current voice pitch multiplier (e.g. 1.0, 1.2).
  final double pitch;

  /// Callback when user changes the pitch via slider, steppers, or preset chips.
  final ValueChanged<double> onPitchChanged;

  /// Optional callback to close or collapse the panel.
  final VoidCallback? onClose;

  static const double minPitch = 0.5;
  static const double maxPitch = 2.0;
  static const double step = 0.05;
  static const List<double> presetPitches = [0.75, 0.9, 1.0, 1.1, 1.25, 1.5];

  static String formatPitch(double p) {
    final s = p.toStringAsFixed(2);
    if (s.endsWith('0')) {
      return '${p.toStringAsFixed(1)}×';
    }
    return '$s×';
  }

  void _stepPitch(double delta) {
    final next = (pitch + delta).clamp(minPitch, maxPitch);
    final rounded = (next / step).round() * step;
    onPitchChanged(double.parse(rounded.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDefaultPitch = (pitch - 1.0).abs() < 0.01;

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
                LucideIcons.audioWaveform,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Voice Pitch',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              // Current Pitch Tag
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
                  formatPitch(pitch),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (!isDefaultPitch) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reset to 1.0×',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () => onPitchChanged(1.0),
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
                  tooltip: 'Close pitch settings',
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
                tooltip: 'Decrease pitch (-0.05×)',
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  foregroundColor: scheme.onSurface,
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(44, 44),
                ),
                onPressed: pitch > minPitch ? () => _stepPitch(-step) : null,
              ),

              // Continuous Slider with 0.05 step divisions
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
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
                    value: pitch.clamp(minPitch, maxPitch),
                    min: minPitch,
                    max: maxPitch,
                    divisions: ((maxPitch - minPitch) / step).round(),
                    label: formatPitch(pitch),
                    onChanged: (val) {
                      final rounded = (val / step).round() * step;
                      onPitchChanged(
                        double.parse(rounded.toStringAsFixed(2)),
                      );
                    },
                  ),
                ),
              ),

              // Increase Stepper Button (>=44pt touch target)
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 18),
                tooltip: 'Increase pitch (+0.05×)',
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  foregroundColor: scheme.onSurface,
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(44, 44),
                ),
                onPressed: pitch < maxPitch ? () => _stepPitch(step) : null,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. One-Tap Preset Chips Row with comfortable touch targets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: presetPitches
                  .map((preset) {
                    final isSelected = (pitch - preset).abs() < 0.02;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => onPitchChanged(preset),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 38,
                            minWidth: 44,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary
                                : scheme.surfaceContainerHighest.withValues(
                                    alpha: 0.5,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            formatPitch(preset),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
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
