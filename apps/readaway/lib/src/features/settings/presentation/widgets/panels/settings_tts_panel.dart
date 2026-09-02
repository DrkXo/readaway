import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../widgets.dart';

class SettingsTtsPanel extends StatelessWidget {
  const SettingsTtsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) =>
          curr.ttsError != null && prev.ttsError != curr.ttsError,
      listener: (context, state) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(state.ttsError!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: const _TtsView(),
    );
  }
}

class _TtsView extends StatelessWidget {
  const _TtsView();

  static Map<String, List<SherpaTtsModelInfo>> _groupedByLanguage(
    List<SherpaTtsModelInfo> models,
  ) {
    final groups = <String, List<SherpaTtsModelInfo>>{};
    for (final m in models) {
      groups.putIfAbsent(m.languageLabel, () => []).add(m);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.ttsAvailableModels != curr.ttsAvailableModels ||
          prev.ttsDownloadedIds != curr.ttsDownloadedIds ||
          prev.ttsActiveModelId != curr.ttsActiveModelId,
      builder: (context, state) {
        if (state.ttsAvailableModels.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final active = state.ttsAvailableModels
            .where((m) => m.id == state.ttsActiveModelId)
            .firstOrNull;

        Widget? previewButton;
        if (active != null) {
          previewButton = IconButton(
            tooltip: 'Preview',
            icon: const Icon(LucideIcons.playCircle),
            onPressed: () => context.read<SettingsBloc>().add(
              SettingsEvent.previewTts(active.id),
            ),
          );
        }

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
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Available voices',
              rows: [
                for (final entry in _groupedByLanguage(
                  state.ttsAvailableModels,
                ).entries)
                  _LanguageGroupTile(
                    language: entry.key,
                    models: entry.value,
                    initiallyExpanded: entry.value.any(
                      (m) => m.id == (state.ttsActiveModelId ?? ''),
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

class _LanguageGroupTile extends StatefulWidget {
  const _LanguageGroupTile({
    required this.language,
    required this.models,
    required this.initiallyExpanded,
  });

  final String language;
  final List<SherpaTtsModelInfo> models;
  final bool initiallyExpanded;

  @override
  State<_LanguageGroupTile> createState() => _LanguageGroupTileState();
}

class _LanguageGroupTileState extends State<_LanguageGroupTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(_LanguageGroupTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.initiallyExpanded &&
        widget.initiallyExpanded &&
        !_expanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.language} (${widget.models.length})',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          for (final model in widget.models) _VoiceTile(model: model),
      ],
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({required this.model});

  final SherpaTtsModelInfo model;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.ttsDownloadOf(model.id) != curr.ttsDownloadOf(model.id) ||
          prev.isTtsDownloaded(model.id) != curr.isTtsDownloaded(model.id) ||
          prev.isTtsActive(model.id) != curr.isTtsActive(model.id) ||
          prev.isTtsBusy(model.id) != curr.isTtsBusy(model.id),
      builder: (context, state) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final download = state.ttsDownloadOf(model.id);
        final isDownloaded = state.isTtsDownloaded(model.id);
        final isActive = state.isTtsActive(model.id);
        final isBusy = state.isTtsBusy(model.id);

        final subtitle = [
          model.languageLabel,
          '${model.approxSizeMb.round()} MB',
          if (model.speakerCount > 0) '${model.speakerCount} voices',
          if (isActive) 'Active',
        ].join(' • ');

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? LucideIcons.mic : LucideIcons.audioLines,
                    size: 20,
                    color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                model.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isBusy) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _VoiceActions(
                    model: model,
                    download: download,
                    isDownloaded: isDownloaded,
                    isActive: isActive,
                    isBusy: isBusy,
                  ),
                ],
              ),
              if (download != null) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: download.stage == ModelDownloadStage.extracting
                      ? null
                      : download.fraction,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    switch (download.stage) {
                      ModelDownloadStage.downloading =>
                        'Downloading ${(download.fraction * 100).round()}%',
                      ModelDownloadStage.extracting => 'Extracting…',
                      _ => '',
                    },
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VoiceActions extends StatelessWidget {
  const _VoiceActions({
    required this.model,
    required this.download,
    required this.isDownloaded,
    required this.isActive,
    required this.isBusy,
  });

  final SherpaTtsModelInfo model;
  final SettingsDownloadStatus? download;
  final bool isDownloaded;
  final bool isActive;
  final bool isBusy;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.displayName}?'),
        content: const Text(
          'The downloaded voice files will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(SettingsEvent.deleteTtsModel(model));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<SettingsBloc>();

    if (download != null) {
      return IconButton(
        tooltip: 'Cancel download',
        icon: const Icon(LucideIcons.x),
        onPressed: () => bloc.add(SettingsEvent.cancelTtsDownload(model.id)),
      );
    }

    if (!isDownloaded) {
      return IconButton(
        tooltip: 'Download',
        icon: const Icon(LucideIcons.download),
        onPressed: () => bloc.add(SettingsEvent.startTtsDownload(model)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Play sample',
          icon: Icon(
            LucideIcons.playCircle,
            color: isBusy ? scheme.onSurfaceVariant : scheme.primary,
          ),
          onPressed: isBusy
              ? null
              : () => bloc.add(SettingsEvent.previewTts(model.id)),
        ),
        if (!isActive)
          TextButton(
            onPressed: isBusy
                ? null
                : () => bloc.add(SettingsEvent.activateTts(model.id)),
            child: const Text('Use'),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              LucideIcons.checkCircle,
              size: 18,
              color: scheme.primary,
            ),
          ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(LucideIcons.trash2),
          onPressed: isBusy ? null : () => _confirmDelete(context),
        ),
      ],
    );
  }
}
