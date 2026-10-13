import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// An interactive controller for TTS prosody and timing:
/// 1. Narration style presets (Audiobook, Balanced, Expressive).
/// 2. Sentence pause slider & steppers (0–1000 ms).
/// 3. Paragraph pause slider & steppers (200–2500 ms).
/// 4. Internal silence scale slider (0%–100%).
/// 5. One-touch reset to defaults.
class TtsProsodyControlPanel extends StatelessWidget {
  const TtsProsodyControlPanel({
    required this.narrationStyle,
    required this.sentenceGapMs,
    required this.paragraphGapMs,
    required this.silenceScale,
    required this.onNarrationStyleChanged,
    required this.onSentenceGapChanged,
    required this.onParagraphGapChanged,
    required this.onSilenceScaleChanged,
    required this.onReset,
    this.onClose,
    super.key,
  });

  final String narrationStyle;
  final int sentenceGapMs;
  final int paragraphGapMs;
  final double silenceScale;

  final ValueChanged<String> onNarrationStyleChanged;
  final ValueChanged<int> onSentenceGapChanged;
  final ValueChanged<int> onParagraphGapChanged;
  final ValueChanged<double> onSilenceScaleChanged;
  final VoidCallback onReset;
  final VoidCallback? onClose;

  bool get _isDefault =>
      narrationStyle == 'balanced' &&
      sentenceGapMs == 500 &&
      paragraphGapMs == 1000 &&
      (silenceScale - 0.2).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

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
          // 1. Header: Icon, Title, Reset, Close
          Row(
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                size: 16,
                color: appColors.buttonBackground,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'prosody & timing',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.topbarForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (!_isDefault) ...[
                MetroPressable(
                  onTap: onReset,
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
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Close prosody settings',
                  child: Semantics(
                    label: 'Close prosody settings',
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

          // 2. Narration Style Chips (Audiobook, Balanced, Expressive)
          Row(
            children: [
              _buildStyleChip(
                context: context,
                label: 'audiobook',
                description: 'calm & steady',
                value: 'audiobook',
                isSelected: narrationStyle == 'audiobook',
              ),
              const SizedBox(width: 6),
              _buildStyleChip(
                context: context,
                label: 'balanced',
                description: 'standard',
                value: 'balanced',
                isSelected: narrationStyle == 'balanced',
              ),
              const SizedBox(width: 6),
              _buildStyleChip(
                context: context,
                label: 'expressive',
                description: 'dynamic',
                value: 'expressive',
                isSelected: narrationStyle == 'expressive',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Sentence Pause Row
          _buildSliderRow(
            context: context,
            label: 'sentence pause',
            displayValue: '$sentenceGapMs ms',
            value: sentenceGapMs.toDouble().clamp(0, 1000),
            min: 0,
            max: 1000,
            step: 50,
            onChanged: (v) => onSentenceGapChanged(v.round()),
            onStep: (delta) {
              final next = (sentenceGapMs + delta).clamp(0, 1000);
              onSentenceGapChanged(next);
            },
          ),

          const SizedBox(height: 8),

          // 4. Paragraph Pause Row
          _buildSliderRow(
            context: context,
            label: 'paragraph pause',
            displayValue: '$paragraphGapMs ms',
            value: paragraphGapMs.toDouble().clamp(200, 2500),
            min: 200,
            max: 2500,
            step: 50,
            onChanged: (v) => onParagraphGapChanged(v.round()),
            onStep: (delta) {
              final next = (paragraphGapMs + delta).clamp(200, 2500);
              onParagraphGapChanged(next);
            },
          ),

          const SizedBox(height: 8),

          // 5. Internal Silence Scale Row
          _buildSilenceSlider(
            context: context,
            label: 'silence scale',
            displayValue: '${(silenceScale * 100).round()}%',
            value: silenceScale.clamp(0.0, 1.0),
            onChanged: onSilenceScaleChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip({
    required BuildContext context,
    required String label,
    required String description,
    required String value,
    required bool isSelected,
  }) {
    final appColors = context.appColors;

    return Expanded(
      child: Tooltip(
        message: '$label: $description',
        child: Semantics(
          label: '$label: $description',
          button: true,
          child: MetroPressable(
            onTap: () => onNarrationStyleChanged(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? appColors.buttonForeground
                          : appColors.topbarForeground,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? appColors.buttonForeground.withValues(alpha: 0.8)
                          : appColors.topbarForeground.withValues(alpha: 0.6),
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

  Widget _buildSliderRow({
    required BuildContext context,
    required String label,
    required String displayValue,
    required double value,
    required double min,
    required double max,
    required int step,
    required ValueChanged<double> onChanged,
    required ValueChanged<int> onStep,
  }) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: appColors.topbarForeground.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: appColors.buttonBackground,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Tooltip(
              message: 'Decrease ($step ms)',
              child: Semantics(
                label: 'Decrease ($step ms)',
                button: true,
                child: MetroPressable(
                  onTap: value > min ? () => onStep(-step) : null,
                  child: Container(
                    width: 32,
                    height: 32,
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
                        size: 14,
                        color: value > min
                            ? appColors.topbarForeground
                            : appColors.topbarForeground.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const MetroSliderThumbShape(
                    thumbRadius: 6,
                  ),
                  trackShape: const RectangularSliderTrackShape(),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: appColors.buttonBackground,
                  inactiveTrackColor: appColors.panelBorder,
                  thumbColor: appColors.buttonBackground,
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: ((max - min) / step).round(),
                  onChanged: (val) {
                    final rounded = ((val - min) / step).round() * step + min;
                    onChanged(rounded.toDouble());
                  },
                ),
              ),
            ),
            Tooltip(
              message: 'Increase ($step ms)',
              child: Semantics(
                label: 'Increase ($step ms)',
                button: true,
                child: MetroPressable(
                  onTap: value < max ? () => onStep(step) : null,
                  child: Container(
                    width: 32,
                    height: 32,
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
                        size: 14,
                        color: value < max
                            ? appColors.topbarForeground
                            : appColors.topbarForeground.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSilenceSlider({
    required BuildContext context,
    required String label,
    required String displayValue,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: appColors.topbarForeground.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: appColors.buttonBackground,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const MetroSliderThumbShape(
              thumbRadius: 6,
            ),
            trackShape: const RectangularSliderTrackShape(),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: appColors.buttonBackground,
            inactiveTrackColor: appColors.panelBorder,
            thumbColor: appColors.buttonBackground,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (val) {
              final rounded = (val * 20).round() / 20.0;
              onChanged(rounded);
            },
          ),
        ),
      ],
    );
  }
}
