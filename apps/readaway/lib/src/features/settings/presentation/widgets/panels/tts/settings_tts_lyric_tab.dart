import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../domain/entity/tts_lyric_style.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../widgets.dart';

/// Lyric view alignment settings (global app settings).
class SettingsTtsLyricTab extends StatelessWidget {
  const SettingsTtsLyricTab({super.key});

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
                      icon: Icon(LucideIcons.alignLeft),
                      tooltip: 'Left',
                    ),
                    ButtonSegment(
                      value: LyricLineAlign.center,
                      icon: Icon(LucideIcons.alignCenter),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricLineAlign.right,
                      icon: Icon(LucideIcons.alignRight),
                      tooltip: 'Right',
                    ),
                    ButtonSegment(
                      value: LyricLineAlign.justify,
                      icon: Icon(LucideIcons.alignJustify),
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
                      icon: Icon(LucideIcons.alignLeft),
                      tooltip: 'Start',
                    ),
                    ButtonSegment(
                      value: LyricContentAlign.center,
                      icon: Icon(LucideIcons.alignCenter),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricContentAlign.end,
                      icon: Icon(LucideIcons.alignRight),
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
                      icon: Icon(LucideIcons.arrowUpToLine),
                      tooltip: 'Start',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.center,
                      icon: Icon(LucideIcons.foldVertical),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.end,
                      icon: Icon(LucideIcons.arrowDownToLine),
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
                      icon: Icon(LucideIcons.arrowUpToLine),
                      tooltip: 'Start',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.center,
                      icon: Icon(LucideIcons.foldVertical),
                      tooltip: 'Center',
                    ),
                    ButtonSegment(
                      value: LyricAnchorAlign.end,
                      icon: Icon(LucideIcons.arrowDownToLine),
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
              if (s.isEmpty) return;
              onChanged(s.first);
            },
          ),
        ],
      ),
    );
  }
}
