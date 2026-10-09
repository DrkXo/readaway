import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/widgets/core_widgets.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../widgets.dart';

/// Reading prosody & timing settings (global app settings).
class SettingsTtsReadingTab extends StatelessWidget {
  const SettingsTtsReadingTab({super.key});

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
