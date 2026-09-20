import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
          // 1. Header: Icon, Title, Reset, Close
          Row(
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Prosody & Timing',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (!_isDefault) ...[
                IconButton(
                  tooltip: 'Reset to defaults',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: onReset,
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
                  tooltip: 'Close prosody settings',
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

          const SizedBox(height: 10),

          // 2. Narration Style Chips (Audiobook, Balanced, Expressive)
          Row(
            children: [
              _buildStyleChip(
                scheme: scheme,
                label: 'Audiobook',
                description: 'Calm & steady',
                value: 'audiobook',
                isSelected: narrationStyle == 'audiobook',
              ),
              const SizedBox(width: 6),
              _buildStyleChip(
                scheme: scheme,
                label: 'Balanced',
                description: 'Standard',
                value: 'balanced',
                isSelected: narrationStyle == 'balanced',
              ),
              const SizedBox(width: 6),
              _buildStyleChip(
                scheme: scheme,
                label: 'Expressive',
                description: 'Dynamic',
                value: 'expressive',
                isSelected: narrationStyle == 'expressive',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Sentence Pause Row
          _buildSliderRow(
            context: context,
            label: 'Sentence pause',
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
            label: 'Paragraph pause',
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
            label: 'Silence scale',
            displayValue: '${(silenceScale * 100).round()}%',
            value: silenceScale.clamp(0.0, 1.0),
            onChanged: onSilenceScaleChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip({
    required ColorScheme scheme,
    required String label,
    required String description,
    required String value,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onNarrationStyleChanged(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.35),
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
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? scheme.onPrimary.withValues(alpha: 0.8)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.minus, size: 14),
              tooltip: 'Decrease ($step ms)',
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                foregroundColor: scheme.onSurface,
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
              onPressed: value > min ? () => onStep(-step) : null,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: scheme.primary,
                  inactiveTrackColor: scheme.surfaceContainerHighest,
                  thumbColor: scheme.primary,
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
            IconButton(
              icon: const Icon(LucideIcons.plus, size: 14),
              tooltip: 'Increase ($step ms)',
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                foregroundColor: scheme.onSurface,
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
              onPressed: value < max ? () => onStep(step) : null,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 14,
            ),
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.surfaceContainerHighest,
            thumbColor: scheme.primary,
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
