import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/routes/routes.dart';
import '../../../../../../core/widgets/core_widgets.dart';
import '../../../bloc/tts_library/tts_library_bloc.dart';
import '../../widgets.dart';

/// Active voice + entry point to the full voice library (a pushed route).
class SettingsTtsVoiceTab extends StatelessWidget {
  const SettingsTtsVoiceTab({super.key});

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
