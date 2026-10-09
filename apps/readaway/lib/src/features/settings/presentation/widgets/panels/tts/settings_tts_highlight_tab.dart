import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/theme/tts_highlight_palette.dart';
import '../../../../../reader/presentation/widgets/viewport/reflowable/tts_speech_highlight.dart';
import '../../../../domain/entity/settings.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../widgets.dart';

/// TTS Speech Highlighting options and live preview.
class SettingsTtsHighlightTab extends StatelessWidget {
  const SettingsTtsHighlightTab({super.key});

  static void _updateSettings(
    BuildContext context,
    SettingsState state,
    GlobalViewSettings Function(GlobalViewSettings) updater,
  ) {
    final gvs = updater(state.appSettings.globalViewSettings);
    final updated = state.appSettings.copyWith(globalViewSettings: gvs);
    context.read<SettingsBloc>().add(SettingsEvent.updateAppSettings(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings !=
          curr.appSettings.globalViewSettings,
      builder: (context, state) {
        final gvs = state.appSettings.globalViewSettings;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Live Interactive Preview
            _HighlightPreviewCard(gvs: gvs),
            const SizedBox(height: 20),

            // Highlighting Style
            ScopedSettingsSection(
              scopable: false,
              title: 'Highlight Style',
              onReset: () => _updateSettings(
                context,
                state,
                (s) => s.copyWith(
                  ttsHighlightStyle: 'highlight',
                  ttsHighlightColor: 'primary',
                  ttsHighlightWordFocus: true,
                  ttsHighlightSentenceOpacity: 0.18,
                  ttsHighlightWordOpacity: 0.38,
                ),
              ),
              rows: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'highlight',
                        icon: Icon(LucideIcons.rectangleHorizontal, size: 18),
                        label: Text('Filled'),
                        tooltip: 'Filled rounded rectangle',
                      ),
                      ButtonSegment(
                        value: 'underline',
                        icon: Icon(LucideIcons.underline, size: 18),
                        label: Text('Underline'),
                        tooltip: 'Clean baseline underline',
                      ),
                      ButtonSegment(
                        value: 'squiggly',
                        icon: Icon(LucideIcons.waves, size: 18),
                        label: Text('Squiggly'),
                        tooltip: 'Wavy underline',
                      ),
                      ButtonSegment(
                        value: 'outline',
                        icon: Icon(LucideIcons.square, size: 18),
                        label: Text('Outline'),
                        tooltip: 'Border outline',
                      ),
                    ],
                    selected: {gvs.ttsHighlightStyle},
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    onSelectionChanged: (s) {
                      if (s.isEmpty) return;
                      _updateSettings(
                        context,
                        state,
                        (curr) => curr.copyWith(ttsHighlightStyle: s.first),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Color Accent
            ScopedSettingsSection(
              scopable: false,
              title: 'Color Accent',
              rows: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: TtsHighlightColorPicker(
                    selectedValue: gvs.ttsHighlightColor,
                    onSelected: (value) => _updateSettings(
                      context,
                      state,
                      (curr) => curr.copyWith(ttsHighlightColor: value),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Karaoke Word Focus
            ScopedSettingsSection(
              scopable: false,
              title: 'Karaoke Word Focus',
              rows: [
                SettingsSwitchRow(
                  label: 'Active word emphasis',
                  description:
                      'Emphasize the currently spoken word with an elevated '
                      'focus pill over the sentence background.',
                  value: gvs.ttsHighlightWordFocus,
                  onChanged: (v) => _updateSettings(
                    context,
                    state,
                    (curr) => curr.copyWith(ttsHighlightWordFocus: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opacity & Intensity
            ScopedSettingsSection(
              scopable: false,
              title: 'Opacity & Intensity',
              rows: [
                SettingsSliderRow(
                  label: 'Sentence opacity',
                  value: gvs.ttsHighlightSentenceOpacity,
                  min: 0.05,
                  max: 0.50,
                  divisions: 9,
                  format: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => _updateSettings(
                    context,
                    state,
                    (curr) => curr.copyWith(
                      ttsHighlightSentenceOpacity: (v * 100).round() / 100.0,
                    ),
                  ),
                ),
                SettingsSliderRow(
                  label: 'Word focus opacity',
                  value: gvs.ttsHighlightWordOpacity,
                  min: 0.20,
                  max: 0.90,
                  divisions: 14,
                  enabled: gvs.ttsHighlightWordFocus,
                  format: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => _updateSettings(
                    context,
                    state,
                    (curr) => curr.copyWith(
                      ttsHighlightWordOpacity: (v * 100).round() / 100.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HighlightPreviewCard extends StatelessWidget {
  const _HighlightPreviewCard({required this.gvs});
  final GlobalViewSettings gvs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E24) : const Color(0xFFF7F7F9);
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final baseColor = resolveTtsHighlightColor(
      gvs.ttsHighlightColor,
      theme.colorScheme,
    );

    final style = switch (gvs.ttsHighlightStyle) {
      'underline' => TtsHighlightStyle.underline,
      'squiggly' => TtsHighlightStyle.squiggly,
      'outline' => TtsHighlightStyle.outline,
      _ => TtsHighlightStyle.highlight,
    };

    const text =
        'The true journey of discovery consists not in seeking new landscapes, but in having new eyes.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.eye,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Sample Preview',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final textSpan = TextSpan(
                text: text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: textColor,
                  fontFamily: 'serif',
                ),
              );
              final textPainter = TextPainter(
                text: textSpan,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              // Whole sentence boxes
              final sentenceBoxes = textPainter.getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: text.length),
                boxHeightStyle: ui.BoxHeightStyle.tight,
              );
              final rects = sentenceBoxes
                  .where((b) => b.right > b.left)
                  .map((b) => Rect.fromLTRB(b.left, b.top, b.right, b.bottom))
                  .toList();

              // Word "discovery" boxes
              final wordStart = text.indexOf('discovery');
              final wordEnd = wordStart + 'discovery'.length;
              final wordBoxes = textPainter.getBoxesForSelection(
                TextSelection(baseOffset: wordStart, extentOffset: wordEnd),
                boxHeightStyle: ui.BoxHeightStyle.tight,
              );
              final wordRects = gvs.ttsHighlightWordFocus
                  ? wordBoxes
                        .where((b) => b.right > b.left)
                        .map(
                          (b) =>
                              Rect.fromLTRB(b.left, b.top, b.right, b.bottom),
                        )
                        .toList()
                  : null;

              final highlightPainter = TtsSpeechHighlightPainter(
                rects: rects,
                wordRects: wordRects,
                sliceTop: 0.0,
                color: baseColor.withValues(
                  alpha: gvs.ttsHighlightSentenceOpacity,
                ),
                wordColor: baseColor.withValues(
                  alpha: gvs.ttsHighlightWordOpacity,
                ),
                style: style,
              );

              return CustomPaint(
                painter: highlightPainter,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: textColor,
                    fontFamily: 'serif',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
