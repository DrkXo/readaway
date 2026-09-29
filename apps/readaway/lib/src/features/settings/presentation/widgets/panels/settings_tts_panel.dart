import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../settings/domain/entity/tts_lyric_style.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/tts_library/tts_library_bloc.dart';
import '../../pages/voice_library_page.dart';
import '../widgets.dart';

/// TTS settings split into three sub-tabs: the active voice (+ voice library
/// entry point), reading prosody & timing, and the lyric view.
///
/// All TTS voice/download state lives in [TtsLibraryBloc]; [SettingsBloc]
/// keeps only the app settings (prosody, lyric style).
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

enum _TtsTab { voice, reading, lyric }

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
                value: _TtsTab.lyric,
                label: Text('Lyric view'),
                icon: Icon(Icons.music_note, size: 16),
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
              _LyricTab(),
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
            SettingsSection(
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
                  onTap: () =>
                      pushSettingsPage(context, const VoiceLibraryPage()),
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
            SettingsSection(
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
            SettingsSection(
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
