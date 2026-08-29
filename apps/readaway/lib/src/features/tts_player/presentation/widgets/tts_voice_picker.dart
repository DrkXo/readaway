import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/services.dart';
import '../../../settings/presentation/bloc/tts/tts_bloc.dart';
import '../bloc/tts_player_bloc.dart';

/// Dropdown of downloaded voices (from the shared [TtsBloc] catalog).
/// Selecting one switches the active voice for playback.
class TtsVoicePicker extends StatelessWidget {
  const TtsVoicePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TtsBloc>.value(
      value: GetIt.I.get<TtsBloc>(),
      child: BlocBuilder<TtsBloc, TtsState>(
        buildWhen: (prev, curr) =>
            prev.downloadedIds != curr.downloadedIds ||
            prev.activeModelId != curr.activeModelId,
        builder: (context, ttsState) {
          final downloaded = ttsState.availableModels
              .where((m) => ttsState.downloadedIds.contains(m.id))
              .toList();
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          if (downloaded.isEmpty) {
            return Row(
              children: [
                Icon(
                  LucideIcons.mic,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No voices downloaded. Add one in Settings → Text to Speech.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          }

          final currentId = ttsState.activeModelId;
          final current = downloaded
              .where((m) => m.id == currentId)
              .firstOrNull;

          return Row(
            children: [
              Icon(
                LucideIcons.mic,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: current?.id,
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, size: 18),
                    hint: const Text('Select voice'),
                    items: [
                      for (final m in downloaded)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            m.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      final model = downloaded
                          .where((m) => m.id == id)
                          .firstOrNull;
                      if (model == null) return;
                      context.read<TtsPlayerBloc>().add(
                        TtsPlayerEvent.setVoice(
                          TtsVoiceOption(
                            engine: TtsEngineKind.sherpaOnnx,
                            id: model.id,
                            label: model.displayName,
                            languageCode: model.languageCode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
