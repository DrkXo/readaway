import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: MetroPivotControl<_TtsTab>(
            value: _tab,
            onChanged: (newTab) => setState(() => _tab = newTab),
            items: const [
              MetroPivotControlItem(
                value: _TtsTab.voice,
                label: 'voice',
                icon: LucideIcons.mic,
              ),
              MetroPivotControlItem(
                value: _TtsTab.reading,
                label: 'reading',
                icon: LucideIcons.slidersHorizontal,
              ),
              MetroPivotControlItem(
                value: _TtsTab.highlight,
                label: 'highlight',
                icon: LucideIcons.highlighter,
              ),
              MetroPivotControlItem(
                value: _TtsTab.lyric,
                label: 'lyric',
                icon: LucideIcons.music,
              ),
              MetroPivotControlItem(
                value: _TtsTab.cache,
                label: 'cache',
                icon: LucideIcons.hardDrive,
              ),
            ],
          ),
        ),
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
