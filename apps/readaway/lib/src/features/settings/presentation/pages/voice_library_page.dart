import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/services.dart';
import '../../../../core/services/tts/tts_download_task.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../bloc/tts_library/tts_library_bloc.dart';
import '../widgets/dialogs/custom_tts_import_dialog.dart';
import '../widgets/widgets.dart';

/// Full voice-library management screen: the grouped voice list, live
/// download status from the [TtsDownloadManager] snapshot stream, and a
/// first-class "Resume interrupted" action for downloads parked after the app
/// closed.
///
/// Pushed from the TTS settings panel (Voice tab). Installed state streams
/// from the Hive-backed model store; download progress replays the manager's
/// snapshots — no legacy progress adapter is involved.
class VoiceLibraryPage extends StatelessWidget {
  const VoiceLibraryPage({super.key});

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SettingsSheetHeader(
          title: 'Voice library',
          leading: SettingsSheetBackButton(),
        ),
        Flexible(
          child: BlocBuilder<TtsLibraryBloc, TtsLibraryState>(
            buildWhen: (prev, curr) =>
                prev.availableModels != curr.availableModels ||
                prev.installedModels != curr.installedModels ||
                prev.activeModelId != curr.activeModelId ||
                prev.busyModelId != curr.busyModelId ||
                prev.downloads != curr.downloads ||
                prev.isCheckingUpdates != curr.isCheckingUpdates,
            builder: (context, state) {
              if (state.availableModels.isEmpty) {
                return const AppLoadingView(label: 'Loading TTS models...');
              }

              final interrupted = state.downloads.values
                  .where((t) => t.phase == TtsDownloadPhase.interrupted)
                  .length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (interrupted > 0) ...[
                    _ResumeInterruptedBanner(count: interrupted),
                    const SizedBox(height: 16),
                  ],
                  SettingsSection(
                    title: 'Available voices',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Import Custom Voice Model',
                          icon: const Icon(
                            LucideIcons.filePlus,
                            size: 18,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => CustomTtsImportDialog.show(context),
                        ),
                        const SizedBox(width: 4),
                        if (state.isCheckingUpdates)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'Check for voice updates from GitHub',
                            icon: const Icon(
                              LucideIcons.refreshCw,
                              size: 16,
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              context.read<TtsLibraryBloc>().add(
                                const TtsLibraryEvent.checkForUpdates(),
                              );
                            },
                          ),
                      ],
                    ),
                    rows: [
                      for (final entry in _groupedByLanguage(
                        state.availableModels,
                      ).entries)
                        _LanguageGroupTile(
                          // Keyed by language: a catalog refresh can
                          // add or drop groups, and without a key the
                          // expanded state would move to whichever group
                          // landed on the same index.
                          key: ValueKey(entry.key),
                          language: entry.key,
                          models: entry.value,
                          initiallyExpanded:
                              entry.key == 'Custom Voices' ||
                              entry.value.any(
                                (m) => m.id == (state.activeModelId ?? ''),
                              ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Prominent, first-class "Resume interrupted" action. Interrupted downloads
/// are never auto-rescheduled at boot; the user resumes them manually.
class _ResumeInterruptedBanner extends StatelessWidget {
  const _ResumeInterruptedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.rotateCcw, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count interrupted download${count == 1 ? '' : 's'} — the app '
              'closed before it finished. Resume to continue where it left off.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: () => context.read<TtsLibraryBloc>().add(
              const TtsLibraryEvent.resumeInterrupted(),
            ),
            icon: const Icon(LucideIcons.play, size: 16),
            label: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}

class _LanguageGroupTile extends StatefulWidget {
  const _LanguageGroupTile({
    super.key,
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
          for (final model in widget.models)
            _VoiceTile(key: ValueKey(model.id), model: model),
      ],
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({super.key, required this.model});

  final SherpaTtsModelInfo model;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TtsLibraryBloc, TtsLibraryState>(
      buildWhen: (prev, curr) =>
          prev.taskOf(model.id) != curr.taskOf(model.id) ||
          prev.isDownloaded(model.id) != curr.isDownloaded(model.id) ||
          prev.isActive(model.id) != curr.isActive(model.id) ||
          prev.isBusy(model.id) != curr.isBusy(model.id) ||
          prev.modelHasUpdate(model.id) != curr.modelHasUpdate(model.id),
      builder: (context, state) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final task = state.taskOf(model.id);
        final isDownloaded = state.isDownloaded(model.id);
        final isActive = state.isActive(model.id);
        final isBusy = state.isBusy(model.id);
        final hasUpdate = state.modelHasUpdate(model.id);
        final showDownload =
            task != null && task.phase != TtsDownloadPhase.done;

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
                    task: task,
                    isDownloaded: isDownloaded,
                    isActive: isActive,
                    isBusy: isBusy,
                    hasUpdate: hasUpdate,
                  ),
                ],
              ),
              if (showDownload) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _progressValue(task),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    _statusLabel(task),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: task.phase == TtsDownloadPhase.failed
                          ? scheme.error
                          : scheme.onSurfaceVariant,
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

  double? _progressValue(TtsDownloadTask task) {
    return switch (task.phase) {
      TtsDownloadPhase.downloadingArchive ||
      TtsDownloadPhase.downloadingAuxiliary ||
      TtsDownloadPhase.paused ||
      TtsDownloadPhase.interrupted => task.fraction,
      // queued / verifying / extracting / finalizing: indeterminate
      _ => null,
    };
  }

  String _statusLabel(TtsDownloadTask task) {
    final speed = _speedLabel(task.speedBytesPerSec);
    final eta = _etaLabel(task.timeRemaining);
    return switch (task.phase) {
      TtsDownloadPhase.queued => 'Queued…',
      TtsDownloadPhase.downloadingArchive ||
      TtsDownloadPhase.downloadingAuxiliary =>
        'Downloading ${(task.fraction * 100).round()}%$speed$eta',
      TtsDownloadPhase.verifyingArchive => 'Verifying download…',
      TtsDownloadPhase.extractingArchive => 'Extracting…',
      TtsDownloadPhase.finalizing => 'Installing…',
      TtsDownloadPhase.paused => 'Paused',
      TtsDownloadPhase.interrupted => 'Interrupted — resume to continue',
      TtsDownloadPhase.failed => task.errorMessage ?? 'Download failed',
      TtsDownloadPhase.done => 'Installed',
    };
  }

  String _speedLabel(double? speed) {
    if (speed == null || speed <= 0) return '';
    if (speed >= 1024 * 1024) {
      return ' • ${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return ' • ${(speed / 1024).toStringAsFixed(0)} KB/s';
  }

  String _etaLabel(Duration? eta) {
    if (eta == null || eta.isNegative) return '';
    if (eta.inSeconds < 60) return ' • ${eta.inSeconds}s left';
    if (eta.inMinutes < 60) return ' • ${eta.inMinutes} min left';
    return ' • ${eta.inHours}h ${eta.inMinutes % 60}m left';
  }
}

class _VoiceActions extends StatelessWidget {
  const _VoiceActions({
    required this.model,
    required this.task,
    required this.isDownloaded,
    required this.isActive,
    required this.isBusy,
    required this.hasUpdate,
  });

  final SherpaTtsModelInfo model;
  final TtsDownloadTask? task;
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
      context.read<TtsLibraryBloc>().add(TtsLibraryEvent.deleteModel(model));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<TtsLibraryBloc>();
    // Local copy so the nullable field promotes after the null check below.
    final task = this.task;
    if (task == null || task.phase == TtsDownloadPhase.done) {
      return _idleActions(bloc, scheme, context);
    }

    return switch (task.phase) {
      TtsDownloadPhase.paused || TtsDownloadPhase.interrupted => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Resume download',
            icon: const Icon(LucideIcons.play),
            onPressed: () => bloc.add(TtsLibraryEvent.resumeDownload(model.id)),
          ),
          IconButton(
            tooltip: 'Cancel download',
            icon: const Icon(LucideIcons.x),
            onPressed: () => bloc.add(TtsLibraryEvent.cancelDownload(model.id)),
          ),
        ],
      ),
      TtsDownloadPhase.failed => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Retry download',
            icon: const Icon(LucideIcons.rotateCw),
            onPressed: () => bloc.add(TtsLibraryEvent.startDownload(model)),
          ),
          IconButton(
            tooltip: 'Cancel',
            icon: const Icon(LucideIcons.x),
            onPressed: () => bloc.add(TtsLibraryEvent.cancelDownload(model.id)),
          ),
        ],
      ),
      // queued / downloading / verifying / extracting / finalizing
      _ => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.phase == TtsDownloadPhase.downloadingArchive ||
              task.phase == TtsDownloadPhase.downloadingAuxiliary)
            IconButton(
              tooltip: 'Pause download',
              icon: const Icon(LucideIcons.pause),
              onPressed: () =>
                  bloc.add(TtsLibraryEvent.pauseDownload(model.id)),
            ),
          IconButton(
            tooltip: 'Cancel download',
            icon: const Icon(LucideIcons.x),
            onPressed: () => bloc.add(TtsLibraryEvent.cancelDownload(model.id)),
          ),
        ],
      ),
    };
  }

  Widget _idleActions(
    TtsLibraryBloc bloc,
    ColorScheme scheme,
    BuildContext context,
  ) {
    final showPreview =
        !model.isCustom && (isDownloaded || model.previewAudioUrl != null);

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
              onPressed: () => bloc.add(TtsLibraryEvent.preview(model.id)),
            ),
          IconButton(
            tooltip: 'Download',
            icon: const Icon(LucideIcons.download),
            onPressed: () => bloc.add(TtsLibraryEvent.startDownload(model)),
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
            icon: Icon(LucideIcons.arrowUpCircle, color: scheme.tertiary),
            onPressed: () => bloc.add(TtsLibraryEvent.startDownload(model)),
          ),
        if (showPreview)
          IconButton(
            tooltip: isBusy ? 'Stop sample' : 'Play sample',
            icon: Icon(
              isBusy ? LucideIcons.square : LucideIcons.playCircle,
              color: scheme.primary,
            ),
            onPressed: () => bloc.add(TtsLibraryEvent.preview(model.id)),
          ),
        if (!isActive)
          TextButton(
            onPressed: isBusy
                ? null
                : () => bloc.add(TtsLibraryEvent.activate(model.id)),
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
