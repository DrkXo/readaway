import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../bloc/tts_library/tts_library_bloc.dart';
import 'tts/settings_tts_cache_tab.dart';
import 'tts/settings_tts_highlight_tab.dart';
import 'tts/settings_tts_lyric_tab.dart';
import 'tts/settings_tts_reading_tab.dart';
import 'tts/settings_tts_voice_tab.dart';

export 'tts/settings_tts_cache_tab.dart'
    show formatStorageBytes, SettingsTtsCacheTab;
export 'tts/settings_tts_highlight_tab.dart' show SettingsTtsHighlightTab;
export 'tts/settings_tts_lyric_tab.dart' show SettingsTtsLyricTab;
export 'tts/settings_tts_reading_tab.dart' show SettingsTtsReadingTab;
export 'tts/settings_tts_voice_tab.dart' show SettingsTtsVoiceTab;

/// TTS settings split into five sub-tabs: the active voice (+ voice library
/// entry point), reading prosody & timing, speech highlight, the lyric view,
/// and audio cache management.
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final selector = SegmentedButton<_TtsTab>(
              segments: const [
                ButtonSegment(
                  value: _TtsTab.voice,
                  label: Text('Voice'),
                  icon: Icon(LucideIcons.mic, size: 16),
                ),
                ButtonSegment(
                  value: _TtsTab.reading,
                  label: Text('Reading'),
                  icon: Icon(LucideIcons.slidersHorizontal, size: 16),
                ),
                ButtonSegment(
                  value: _TtsTab.highlight,
                  label: Text('Highlight'),
                  icon: Icon(LucideIcons.highlighter, size: 16),
                ),
                ButtonSegment(
                  value: _TtsTab.lyric,
                  label: Text('Lyric'),
                  icon: Icon(LucideIcons.music, size: 16),
                ),
                ButtonSegment(
                  value: _TtsTab.cache,
                  label: Text('Cache'),
                  icon: Icon(LucideIcons.hardDrive, size: 16),
                ),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              expandedInsets: isNarrow ? null : EdgeInsets.zero,
              onSelectionChanged: (s) {
                // A segmented button reports an empty selection when the pressed
                // segment is tapped again; there is nothing to switch to.
                if (s.isEmpty) return;
                setState(() => _tab = s.first);
              },
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: isNarrow
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: selector,
                    )
                  : selector,
            );
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: _tab.index,
            children: const [
              SettingsTtsVoiceTab(),
              SettingsTtsReadingTab(),
              SettingsTtsHighlightTab(),
              SettingsTtsLyricTab(),
              SettingsTtsCacheTab(),
            ],
          ),
        ),
      ],
    );
  }
}
