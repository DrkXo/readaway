import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../reader/presentation/widgets/viewport/reflowable/tts_speech_highlight.dart';
import '../../../../settings/domain/entity/settings.dart';
import '../../../../settings/domain/entity/tts_lyric_style.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/tts_library/tts_library_bloc.dart';
import '../reader_prefs_scope.dart';
import '../widgets.dart';

/// TTS settings split into four sub-tabs: the active voice (+ voice library
/// entry point), reading prosody & timing, the lyric view, and audio cache
/// management.
///
/// All TTS voice/download and cache state lives in [TtsLibraryBloc];
/// [SettingsBloc] keeps only the app settings (prosody, lyric style, cache limits).
class SettingsTtsPanel extends StatelessWidget {
  const SettingsTtsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TtsLibraryBloc, TtsLibraryState>(
          listenWhen: (prev, curr) =>
              curr.error != null && prev.error != curr.error,
          listener: (context, state) {
            context.showErrorToast(state.error!);
          },
        ),
        BlocListener<TtsLibraryBloc, TtsLibraryState>(
          listenWhen: (prev, curr) =>
              curr.updateNotification != null &&
              prev.updateNotification != curr.updateNotification,
          listener: (context, state) {
            if (state.updateNotification != null) {
              context.showInfoToast(state.updateNotification!);
            }
          },
        ),
      ],
      child: const _TtsView(),
    );
  }
}

enum _TtsTab { voice, reading, highlight, lyric, cache }

class _TtsView extends StatefulWidget {
  const _TtsView();

  @override
  State<_TtsView> createState() => _TtsViewState();
}

class _TtsViewState extends State<_TtsView> {
  _TtsTab _tab = _TtsTab.voice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<_TtsTab>(
            segments: const [
              ButtonSegment(
                value: _TtsTab.voice,
                label: Text('Voice'),
                icon: Icon(Icons.mic, size: 16),
              ),
              ButtonSegment(
                value: _TtsTab.reading,
                label: Text('Reading'),
                icon: Icon(Icons.tune, size: 16),
              ),
              ButtonSegment(
                value: _TtsTab.highlight,
                label: Text('Highlight'),
                icon: Icon(Icons.border_color_outlined, size: 16),
              ),
              ButtonSegment(
                value: _TtsTab.lyric,
                label: Text('Lyric'),
                icon: Icon(Icons.music_note, size: 16),
              ),
              ButtonSegment(
                value: _TtsTab.cache,
                label: Text('Cache'),
                icon: Icon(LucideIcons.hardDrive, size: 16),
              ),
            ],
            selected: {_tab},
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: (s) {
              // A segmented button reports an empty selection when the pressed
              // segment is tapped again; there is nothing to switch to.
              if (s.isEmpty) return;
              setState(() => _tab = s.first);
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: _tab.index,
            children: const [
              _VoiceTab(),
              _ReadingTab(),
              _HighlightTab(),
              _LyricTab(),
              _CacheTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Active voice + entry point to the full voice library (a pushed route).
class _VoiceTab extends StatelessWidget {
  const _VoiceTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TtsLibraryBloc, TtsLibraryState>(
      buildWhen: (prev, curr) =>
          prev.availableModels != curr.availableModels ||
          prev.installedModels != curr.installedModels ||
          prev.activeModelId != curr.activeModelId ||
          prev.busyModelId != curr.busyModelId ||
          prev.downloads != curr.downloads,
      builder: (context, state) {
        if (state.availableModels.isEmpty) {
          return const AppLoadingView(label: 'Loading TTS models...');
        }

        final active = state.availableModels
            .where((m) => m.id == state.activeModelId)
            .firstOrNull;
        final activeDownloads = state.downloads.values
            .where((t) => t.phase.isActive)
            .length;

        Widget? previewButton;
        if (active != null) {
          final isBusy = state.isBusy(active.id);
          previewButton = IconButton(
            tooltip: isBusy ? 'Stop' : 'Preview',
            icon: Icon(isBusy ? LucideIcons.square : LucideIcons.playCircle),
            onPressed: () => context.read<TtsLibraryBloc>().add(
              TtsLibraryEvent.preview(active.id),
            ),
          );
        }

        final summary = [
          '${state.installedModels.length} of '
              '${state.availableModels.length} voices installed',
          if (activeDownloads > 0) '$activeDownloads downloading',
        ].join(' • ');

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            ScopedSettingsSection(
              scopable: false,
              title: 'Voice',
              rows: [
                SettingsRow(
                  label: 'Active voice',
                  description: active?.displayName ?? 'None selected',
                  trailing: previewButton,
                ),
                SettingsRow(
                  label: 'Manage voices',
                  description: summary,
                  onTap: () => context.push(appRoutes.settingsVoices.path),
                  trailing: const Icon(LucideIcons.chevronRight, size: 20),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Reading prosody & timing settings (global app settings).
class _ReadingTab extends StatelessWidget {
  const _ReadingTab();

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
            ScopedSettingsSection(
              scopable: false,
              title: 'Reading Prosody & Timing',
              rows: [
                SettingsSelectRow<String>(
                  label: 'Narration style',
                  description: 'Adjusts voice expression and pitch variance',
                  value: gvs.ttsNarrationStyle,
                  entries: const [
                    SettingsSelectEntry(
                      value: 'audiobook',
                      label: 'Audiobook (Calm & steady)',
                    ),
                    SettingsSelectEntry(
                      value: 'balanced',
                      label: 'Balanced (Standard)',
                    ),
                    SettingsSelectEntry(
                      value: 'expressive',
                      label: 'Expressive (Dynamic)',
                    ),
                  ],
                  onChanged: (style) {
                    final updated = state.appSettings.copyWith(
                      globalViewSettings: gvs.copyWith(
                        ttsNarrationStyle: style,
                      ),
                    );
                    context.read<SettingsBloc>().add(
                      SettingsEvent.updateAppSettings(updated),
                    );
                  },
                ),
                SettingsSliderRow(
                  label: 'Sentence pause',
                  value: gvs.ttsSentenceGap.toDouble(),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  format: (v) => '${v.round()} ms',
                  onChanged: (val) {
                    final updated = state.appSettings.copyWith(
                      globalViewSettings: gvs.copyWith(
                        ttsSentenceGap: val.round(),
                      ),
                    );
                    context.read<SettingsBloc>().add(
                      SettingsEvent.updateAppSettings(updated),
                    );
                  },
                ),
                SettingsSliderRow(
                  label: 'Paragraph pause',
                  value: gvs.ttsParagraphGap.toDouble(),
                  min: 200,
                  max: 2500,
                  divisions: 23,
                  format: (v) => '${v.round()} ms',
                  onChanged: (val) {
                    final updated = state.appSettings.copyWith(
                      globalViewSettings: gvs.copyWith(
                        ttsParagraphGap: val.round(),
                      ),
                    );
                    context.read<SettingsBloc>().add(
                      SettingsEvent.updateAppSettings(updated),
                    );
                  },
                ),
                SettingsSliderRow(
                  label: 'Model silence scale',
                  value: gvs.ttsSilenceScale,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  format: (v) => '${(v * 100).round()}%',
                  onChanged: (val) {
                    final updated = state.appSettings.copyWith(
                      globalViewSettings: gvs.copyWith(
                        ttsSilenceScale: (val * 100).round() / 100.0,
                      ),
                    );
                    context.read<SettingsBloc>().add(
                      SettingsEvent.updateAppSettings(updated),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// TTS Speech Highlighting options and live preview.
class _HighlightTab extends StatelessWidget {
  const _HighlightTab();

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
                        icon: Icon(Icons.crop_landscape, size: 18),
                        label: Text('Filled'),
                        tooltip: 'Filled rounded rectangle',
                      ),
                      ButtonSegment(
                        value: 'underline',
                        icon: Icon(Icons.format_underlined, size: 18),
                        label: Text('Underline'),
                        tooltip: 'Clean baseline underline',
                      ),
                      ButtonSegment(
                        value: 'squiggly',
                        icon: Icon(Icons.waves, size: 18),
                        label: Text('Squiggly'),
                        tooltip: 'Wavy underline',
                      ),
                      ButtonSegment(
                        value: 'outline',
                        icon: Icon(Icons.check_box_outline_blank, size: 18),
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
                  child: _ColorPalettePicker(
                    selectedKey: gvs.ttsHighlightColor,
                    onSelected: (key) => _updateSettings(
                      context,
                      state,
                      (curr) => curr.copyWith(ttsHighlightColor: key),
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
                if (gvs.ttsHighlightWordFocus)
                  SettingsSliderRow(
                    label: 'Word focus opacity',
                    value: gvs.ttsHighlightWordOpacity,
                    min: 0.20,
                    max: 0.90,
                    divisions: 14,
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

    final baseColor = switch (gvs.ttsHighlightColor) {
      'amber' => const Color(0xFFF59E0B),
      'emerald' => const Color(0xFF10B981),
      'sky' => const Color(0xFF0EA5E9),
      'violet' => const Color(0xFF8B5CF6),
      'rose' => const Color(0xFFF43F5E),
      _ => theme.colorScheme.primary,
    };

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
                Icons.visibility,
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

class _ColorPalettePicker extends StatelessWidget {
  const _ColorPalettePicker({
    required this.selectedKey,
    required this.onSelected,
  });

  final String selectedKey;
  final ValueChanged<String> onSelected;

  static const _palette = [
    (key: 'primary', label: 'Primary', color: null),
    (key: 'amber', label: 'Amber', color: Color(0xFFF59E0B)),
    (key: 'emerald', label: 'Emerald', color: Color(0xFF10B981)),
    (key: 'sky', label: 'Sky', color: Color(0xFF0EA5E9)),
    (key: 'violet', label: 'Violet', color: Color(0xFF8B5CF6)),
    (key: 'rose', label: 'Rose', color: Color(0xFFF43F5E)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _palette.map((item) {
        final isSelected = selectedKey == item.key;
        final color = item.color ?? theme.colorScheme.primary;

        return InkWell(
          onTap: () => onSelected(item.key),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? color : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Lyric view alignment settings (global app settings).
class _LyricTab extends StatelessWidget {
  const _LyricTab();

  /// Writes the whole lyric-view block back as one value.
  ///
  /// All four alignments move together and are reset together, so they are
  /// replaced as a unit rather than merged field by field — the same reason
  /// they share one entity on the settings side.
  static void _writeLyricStyle(
    BuildContext context,
    SettingsState state,
    TtsLyricStyle style,
  ) {
    final updated = state.appSettings.copyWith(
      globalViewSettings: state.appSettings.globalViewSettings.copyWith(
        ttsLyricStyle: style,
      ),
    );
    context.read<SettingsBloc>().add(
      SettingsEvent.updateAppSettings(updated),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings !=
          curr.appSettings.globalViewSettings,
      builder: (context, state) {
        final lyricStyle = state.appSettings.globalViewSettings.ttsLyricStyle;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            ScopedSettingsSection(
              scopable: false,
              title: 'Lyric view',
              onReset: () => _writeLyricStyle(
                context,
                state,
                const TtsLyricStyle(),
              ),
              rows: [
                _LyricAlignRow<LyricLineAlign>(
                  label: 'Line text alignment',
                  description:
                      'Aligns a sentence that wraps onto a second line. A '
                      'sentence that fits on one line has no slack to '
                      'distribute, so this changes nothing there.',
                  value: lyricStyle.lineAlign,
                  segments: const [
                    ButtonSegment(
                      value: LyricLineAlign.left,
                      icon: Icon(Icons.format_align_left),
                      tooltip: 'Left',
                    ),
                    ButtonSegment(
                      value: LyricLineAlign.center,
                      icon: Icon(Icons.format_align_center),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricLineAlign.right,
                      icon: Icon(Icons.format_align_right),
                      tooltip: 'Right',
                    ),
                    ButtonSegment(
                      value: LyricLineAlign.justify,
                      icon: Icon(Icons.format_align_justify),
                      tooltip: 'Justify',
                    ),
                  ],
                  onChanged: (v) => _writeLyricStyle(
                    context,
                    state,
                    lyricStyle.copyWith(lineAlign: v),
                  ),
                ),
                _LyricAlignRow<LyricContentAlign>(
                  label: 'Content alignment',
                  description:
                      'Which edge of the view a sentence sits on. This is the '
                      'one that moves sentences across the screen.',
                  value: lyricStyle.contentAlign,
                  segments: const [
                    ButtonSegment(
                      value: LyricContentAlign.start,
                      icon: Icon(Icons.align_horizontal_left),
                      tooltip: 'Start',
                    ),
                    ButtonSegment(
                      value: LyricContentAlign.center,
                      icon: Icon(Icons.align_horizontal_center),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricContentAlign.end,
                      icon: Icon(Icons.align_horizontal_right),
                      tooltip: 'End',
                    ),
                  ],
                  onChanged: (v) => _writeLyricStyle(
                    context,
                    state,
                    lyricStyle.copyWith(contentAlign: v),
                  ),
                ),
                _LyricAlignRow<LyricAnchorAlign>(
                  label: 'Tapped line anchor',
                  description:
                      'Which part of a tapped line the view scrolls to. '
                      'Ignored on a sentence with no rewritten text beneath '
                      'it.',
                  value: lyricStyle.selectionAnchorAlign,
                  segments: const [
                    ButtonSegment(
                      value: LyricAnchorAlign.start,
                      icon: Icon(Icons.vertical_align_top),
                      tooltip: 'Start',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.center,
                      icon: Icon(Icons.vertical_align_center),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.end,
                      icon: Icon(Icons.vertical_align_bottom),
                      tooltip: 'End',
                    ),
                  ],
                  onChanged: (v) => _writeLyricStyle(
                    context,
                    state,
                    lyricStyle.copyWith(selectionAnchorAlign: v),
                  ),
                ),
                _LyricAlignRow<LyricAnchorAlign>(
                  label: 'Playing line anchor',
                  description:
                      'Which part of the line being spoken the highlight '
                      'parks on. Also ignored where nothing was rewritten.',
                  value: lyricStyle.activeAnchorAlign,
                  segments: const [
                    ButtonSegment(
                      value: LyricAnchorAlign.start,
                      icon: Icon(Icons.vertical_align_top),
                      tooltip: 'Start',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.center,
                      icon: Icon(Icons.vertical_align_center),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.end,
                      icon: Icon(Icons.vertical_align_bottom),
                      tooltip: 'End',
                    ),
                  ],
                  onChanged: (v) => _writeLyricStyle(
                    context,
                    state,
                    lyricStyle.copyWith(activeAnchorAlign: v),
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

class _LyricAlignRow<T> extends StatelessWidget {
  const _LyricAlignRow({
    required this.label,
    required this.description,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  final String label;
  final String description;
  final T value;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<T>(
            segments: segments,
            selected: {value},
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: (s) {
              // A segmented button reports an empty selection when the pressed
              // segment is tapped again; there is nothing to write in that
              // case, and acting on it would deselect the row.
              if (s.isEmpty) return;
              onChanged(s.first);
            },
          ),
        ],
      ),
    );
  }
}

/// Formats raw byte count into human-readable size string.
String formatStorageBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// TTS audio cache inspection, cleanup, and policy settings.
class _CacheTab extends StatefulWidget {
  const _CacheTab();

  @override
  State<_CacheTab> createState() => _CacheTabState();
}

class _CacheTabState extends State<_CacheTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bookPath = context.readerPrefsDocumentPath();
      context.read<TtsLibraryBloc>().add(
        TtsLibraryEvent.loadCacheSize(bookPath: bookPath),
      );
    });
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all TTS cache?'),
        content: const Text(
          'This will permanently delete all synthesized chapter audio from disk. '
          'Downloaded voice models will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TtsLibraryBloc>().add(const TtsLibraryEvent.clearAllCache());
    }
  }

  Future<void> _confirmClearBook(BuildContext context, String bookPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear book audio cache?'),
        content: const Text(
          'This will remove all synthesized audio chunks for this book. '
          'Audio will be synthesized again when played.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TtsLibraryBloc>().add(
        TtsLibraryEvent.clearBookCache(bookPath),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookPath = context.readerPrefsDocumentPath();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<TtsLibraryBloc, TtsLibraryState>(
      buildWhen: (prev, curr) =>
          prev.totalCacheSizeBytes != curr.totalCacheSizeBytes ||
          prev.bookCacheSizeBytes != curr.bookCacheSizeBytes ||
          prev.isLoadingCacheSize != curr.isLoadingCacheSize ||
          prev.isClearingCache != curr.isClearingCache,
      builder: (context, libState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (prev, curr) =>
              prev.appSettings.globalViewSettings !=
              curr.appSettings.globalViewSettings,
          builder: (context, settingsState) {
            final gvs = settingsState.appSettings.globalViewSettings;
            final totalBytes = libState.totalCacheSizeBytes ?? 0;
            final bookBytes = libState.bookCacheSizeBytes ?? 0;
            final hasBookCache = bookPath != null && bookBytes > 0;
            final hasTotalCache = totalBytes > 0;

            final totalSizeWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (libState.isLoadingCacheSize)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    formatStorageBytes(totalBytes),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  tooltip: 'Refresh cache size',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      libState.isLoadingCacheSize || libState.isClearingCache
                      ? null
                      : () => context.read<TtsLibraryBloc>().add(
                          TtsLibraryEvent.loadCacheSize(bookPath: bookPath),
                        ),
                ),
              ],
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                ScopedSettingsSection(
                  scopable: false,
                  title: 'Audio Cache',
                  rows: [
                    SettingsRow(
                      label: 'Total audio cache',
                      description: 'Pre-rendered chapter audio on device',
                      trailing: totalSizeWidget,
                    ),
                    if (bookPath != null)
                      SettingsRow(
                        label: 'Current book cache',
                        description: 'Audio synthesized for this book',
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            formatStorageBytes(bookBytes),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    if (hasBookCache)
                      SettingsRow(
                        label: 'Clear this book\'s cache',
                        description:
                            'Remove cached chapters for this book only',
                        trailing: IconButton(
                          icon: Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: scheme.error,
                          ),
                          tooltip: 'Clear book cache',
                          onPressed: libState.isClearingCache
                              ? null
                              : () => _confirmClearBook(context, bookPath),
                        ),
                        onTap: libState.isClearingCache
                            ? null
                            : () => _confirmClearBook(context, bookPath),
                      ),
                    SettingsRow(
                      label: 'Clear all TTS cache',
                      description: hasTotalCache
                          ? 'Delete all cached chapters across all books'
                          : 'No cached audio on device',
                      trailing: IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: hasTotalCache ? scheme.error : scheme.outline,
                        ),
                        tooltip: 'Clear all cache',
                        onPressed: hasTotalCache && !libState.isClearingCache
                            ? () => _confirmClearAll(context)
                            : null,
                      ),
                      onTap: hasTotalCache && !libState.isClearingCache
                          ? () => _confirmClearAll(context)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ScopedSettingsSection(
                  scopable: false,
                  title: 'Cache Policy',
                  rows: [
                    SettingsSelectRow<int>(
                      label: 'Maximum cache size',
                      description: 'Oldest chapter audio is evicted when limit is reached',
                      value: gvs.ttsMaxCacheSizeMb,
                      entries: const [
                        SettingsSelectEntry(value: 100, label: '100 MB'),
                        SettingsSelectEntry(value: 250, label: '250 MB'),
                        SettingsSelectEntry(
                          value: 500,
                          label: '500 MB (Default)',
                        ),
                        SettingsSelectEntry(value: 1024, label: '1 GB'),
                        SettingsSelectEntry(value: 2048, label: '2 GB'),
                        SettingsSelectEntry(value: 0, label: 'Unlimited'),
                      ],
                      onChanged: (limit) {
                        final updated = settingsState.appSettings.copyWith(
                          globalViewSettings: gvs.copyWith(
                            ttsMaxCacheSizeMb: limit,
                          ),
                        );
                        context.read<SettingsBloc>().add(
                          SettingsEvent.updateAppSettings(updated),
                        );
                        if (limit > 0) {
                          GetIt.I
                              .get<TtsChapterCacheService>()
                              .enforceCacheLimit(limit * 1024 * 1024);
                          context.read<TtsLibraryBloc>().add(
                            TtsLibraryEvent.loadCacheSize(
                              bookPath: bookPath,
                            ),
                          );
                        }
                      },
                    ),
                    SettingsSwitchRow(
                      label: 'Pre-cache next chapter',
                      description: 'Synthesize upcoming chapter in the background for continuous playback',
                      value: gvs.ttsPrecacheNextChapter,
                      onChanged: (val) {
                        final updated = settingsState.appSettings.copyWith(
                          globalViewSettings: gvs.copyWith(
                            ttsPrecacheNextChapter: val,
                          ),
                        );
                        context.read<SettingsBloc>().add(
                          SettingsEvent.updateAppSettings(updated),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
