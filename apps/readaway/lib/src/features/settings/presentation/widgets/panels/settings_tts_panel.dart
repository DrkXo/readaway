import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../dialogs/custom_tts_import_dialog.dart';
import '../widgets.dart';

class SettingsTtsPanel extends StatelessWidget {
  const SettingsTtsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
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
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (prev, curr) =>
              curr.ttsUpdateNotification != null &&
              prev.ttsUpdateNotification != curr.ttsUpdateNotification,
          listener: (context, state) {
            if (state.ttsUpdateNotification != null) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(
                  content: Text(state.ttsUpdateNotification!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
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
      final label = m.isCustom ? 'Custom Voices' : m.languageLabel;
      groups.putIfAbsent(label, () => []).add(m);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.ttsAvailableModels != curr.ttsAvailableModels ||
          prev.ttsInstalledModels != curr.ttsInstalledModels ||
          prev.ttsDownloadedIds != curr.ttsDownloadedIds ||
          prev.ttsActiveModelId != curr.ttsActiveModelId ||
          prev.isCheckingTtsUpdates != curr.isCheckingTtsUpdates ||
          prev.appSettings.globalViewSettings !=
              curr.appSettings.globalViewSettings,
      builder: (context, state) {
        if (state.ttsAvailableModels.isEmpty) {
          return const AppLoadingView(label: 'Loading TTS models...');
        }

        final active = state.ttsAvailableModels
            .where((m) => m.id == state.ttsActiveModelId)
            .firstOrNull;

        Widget? previewButton;
        if (active != null) {
          final isBusy = state.isTtsBusy(active.id);
          previewButton = IconButton(
            tooltip: isBusy ? 'Stop' : 'Preview',
            icon: Icon(isBusy ? LucideIcons.square : LucideIcons.playCircle),
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
              title: 'Reading Prosody & Timing',
              rows: [
                SettingsSelectRow<String>(
                  label: 'Narration style',
                  description: 'Adjusts voice expression and pitch variance',
                  value: state.appSettings.globalViewSettings.ttsNarrationStyle,
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
                    final gvs = state.appSettings.globalViewSettings;
                    final updated = state.appSettings.copyWith(
                      globalViewSettings: gvs.copyWith(ttsNarrationStyle: style),
                    );
                    context.read<SettingsBloc>().add(
                          SettingsEvent.updateAppSettings(updated),
                        );
                  },
                ),
                SettingsSliderRow(
                  label: 'Sentence pause',
                  value: state.appSettings.globalViewSettings.ttsSentenceGap
                      .toDouble(),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  format: (v) => '${v.round()} ms',
                  onChanged: (val) {
                    final gvs = state.appSettings.globalViewSettings;
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
                  value: state.appSettings.globalViewSettings.ttsParagraphGap
                      .toDouble(),
                  min: 200,
                  max: 2500,
                  divisions: 23,
                  format: (v) => '${v.round()} ms',
                  onChanged: (val) {
                    final gvs = state.appSettings.globalViewSettings;
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
                  value:
                      state.appSettings.globalViewSettings.ttsSilenceScale,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  format: (v) => '${(v * 100).round()}%',
                  onChanged: (val) {
                    final gvs = state.appSettings.globalViewSettings;
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
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Available voices',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Import Custom Voice Model',
                    icon: const Icon(LucideIcons.filePlus, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => CustomTtsImportDialog.show(context),
                  ),
                  const SizedBox(width: 4),
                  if (state.isCheckingTtsUpdates)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Check for voice updates from GitHub',
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        context.read<SettingsBloc>().add(
                              const SettingsEvent.checkForTtsUpdates(),
                            );
                      },
                    ),
                ],
              ),
              rows: [
                for (final entry in _groupedByLanguage(
                  state.ttsAvailableModels,
                ).entries)
                  _LanguageGroupTile(
                    language: entry.key,
                    models: entry.value,
                    initiallyExpanded: entry.key == 'Custom Voices' ||
                        entry.value.any(
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: widget.language == 'Custom Voices'
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
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
          prev.isTtsBusy(model.id) != curr.isTtsBusy(model.id) ||
          prev.modelHasUpdate(model.id) != curr.modelHasUpdate(model.id),
      builder: (context, state) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final download = state.ttsDownloadOf(model.id);
        final isDownloaded = state.isTtsDownloaded(model.id);
        final isActive = state.isTtsActive(model.id);
        final isBusy = state.isTtsBusy(model.id);
        final hasUpdate = state.modelHasUpdate(model.id);

        final subtitle = [
          if (model.isCustom) 'Custom' else model.languageLabel,
          if (model.familyLabel != null) model.familyLabel!,
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
                            if (model.isCustom) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Custom',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSecondaryContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            if (hasUpdate) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Update Available',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            if (isBusy) ...[
                              const SizedBox(width: 8),
                              SpinKitPulsingGrid(
                                color: scheme.primary,
                                size: 14,
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
                    hasUpdate: hasUpdate,
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
                        'Downloading ${(download.fraction * 100).round()}%'
                            '${_speedLabel(download)}${_etaLabel(download)}',
                      ModelDownloadStage.paused => 'Paused',
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

  String _speedLabel(SettingsDownloadStatus download) {
    final speed = download.speedBytesPerSec;
    if (speed == null || speed <= 0) return '';
    if (speed >= 1024 * 1024) {
      return ' • ${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return ' • ${(speed / 1024).toStringAsFixed(0)} KB/s';
  }

  String _etaLabel(SettingsDownloadStatus download) {
    final eta = download.timeRemaining;
    if (eta == null || eta.isNegative) return '';
    if (eta.inSeconds < 60) return ' • ${eta.inSeconds}s left';
    if (eta.inMinutes < 60) return ' • ${eta.inMinutes} min left';
    return ' • ${eta.inHours}h ${eta.inMinutes % 60}m left';
  }
}

class _VoiceActions extends StatelessWidget {
  const _VoiceActions({
    required this.model,
    required this.download,
    required this.isDownloaded,
    required this.isActive,
    required this.isBusy,
    required this.hasUpdate,
  });

  final SherpaTtsModelInfo model;
  final SettingsDownloadStatus? download;
  final bool isDownloaded;
  final bool isActive;
  final bool isBusy;
  final bool hasUpdate;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.displayName}?'),
        content: Text(
          model.isCustom
              ? 'The custom voice model files will be deleted.'
              : 'The downloaded voice files will be removed from this device.',
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
    final download = this.download;

    if (download != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (download.stage == ModelDownloadStage.paused)
            IconButton(
              tooltip: 'Resume download',
              icon: const Icon(LucideIcons.play),
              onPressed: () =>
                  bloc.add(SettingsEvent.resumeTtsDownload(model.id)),
            )
          else if (download.stage == ModelDownloadStage.downloading)
            IconButton(
              tooltip: 'Pause download',
              icon: const Icon(LucideIcons.pause),
              onPressed: () =>
                  bloc.add(SettingsEvent.pauseTtsDownload(model.id)),
            ),
          IconButton(
            tooltip: 'Cancel download',
            icon: const Icon(LucideIcons.x),
            onPressed: () =>
                bloc.add(SettingsEvent.cancelTtsDownload(model.id)),
          ),
        ],
      );
    }

    final showPreview = !model.isCustom &&
        (isDownloaded || model.previewAudioUrl != null);

    if (!isDownloaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPreview)
            IconButton(
              tooltip: isBusy ? 'Stop sample' : 'Play sample',
              icon: Icon(
                isBusy ? LucideIcons.square : LucideIcons.playCircle,
                color: scheme.primary,
              ),
              onPressed: () => bloc.add(SettingsEvent.previewTts(model.id)),
            ),
          IconButton(
            tooltip: 'Download',
            icon: const Icon(LucideIcons.download),
            onPressed: () => bloc.add(SettingsEvent.startTtsDownload(model)),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasUpdate)
          IconButton(
            tooltip: 'Update voice model to latest version',
            icon: Icon(
              LucideIcons.arrowUpCircle,
              color: scheme.tertiary,
            ),
            onPressed: () => bloc.add(SettingsEvent.startTtsDownload(model)),
          ),
        if (showPreview)
          IconButton(
            tooltip: isBusy ? 'Stop sample' : 'Play sample',
            icon: Icon(
              isBusy ? LucideIcons.square : LucideIcons.playCircle,
              color: scheme.primary,
            ),
            onPressed: () => bloc.add(SettingsEvent.previewTts(model.id)),
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
