import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:readaway/src/core/services/services.dart';

/// Manages sherpa-onnx offline voices: browse the catalog, download /
/// cancel / delete voice packs, activate one for read-aloud, play a sample.
class TtsManagerWidget extends StatefulWidget {
  const TtsManagerWidget({super.key});

  @override
  State<TtsManagerWidget> createState() => _TtsManagerWidgetState();
}

class _TtsManagerWidgetState extends State<TtsManagerWidget> {
  final SherpaOnnxTtsService _service = GetIt.I<SherpaOnnxTtsService>();

  Set<String> _downloadedIds = {};
  String? _activeId;
  String? _busyId; // model currently being loaded or previewed

  final _downloads = <String, _ActiveDownload>{};

  @override
  void initState() {
    super.initState();
    _refresh();
    _activeId = _service.activeModel?.id;
  }

  @override
  void dispose() {
    for (final d in _downloads.values) {
      d.sub.cancel();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    final models = await _service.getDownloadedModels();
    if (!mounted) return;
    setState(() {
      _downloadedIds = models.map((m) => m.id).toSet();
      _activeId = _service.activeModel?.id ?? _activeId;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _download(SherpaTtsModelInfo model) {
    final id = model.id;
    late final StreamSubscription<ModelDownloadProgress> sub;
    sub = _service
        .downloadModel(model)
        .listen(
          (progress) {
            final active = _downloads[id];
            if (progress.stage == ModelDownloadStage.done) {
              _downloads.remove(id);
              _refresh();
            } else if (progress.stage == ModelDownloadStage.failed) {
              _downloads.remove(id);
              _snack('Failed to download ${model.displayName}');
            } else if (active != null) {
              active
                ..stage = progress.stage
                ..fraction = progress.fraction;
            }
            if (mounted) setState(() {});
          },
          onError: (Object e) {
            _downloads.remove(id);
            if (mounted) setState(() {});
          },
          cancelOnError: true,
        );
    setState(() => _downloads[id] = _ActiveDownload(sub));
  }

  Future<void> _delete(SherpaTtsModelInfo model) async {
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
    if (confirmed != true) return;

    await _service.deleteModel(model.id);
    if (_activeId == model.id) _activeId = null;
    await _refresh();
  }

  Future<void> _activate(SherpaTtsModelInfo model) async {
    if (_busyId != null) return;
    setState(() => _busyId = model.id);
    try {
      if (_service.activeModel?.id != model.id) {
        await _service.loadModel(model.id);
      }
      setState(() => _activeId = model.id);
    } on SherpaTtsException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _preview(SherpaTtsModelInfo model) async {
    if (_busyId != null) return;
    setState(() => _busyId = model.id);
    try {
      if (_service.activeModel?.id != model.id) {
        await _service.loadModel(model.id);
      }
      setState(() => _activeId = model.id);

      final tmp = await getTemporaryDirectory();
      final file = await _service.synthesizeToFile(
        text: 'Hello. This is what this voice sounds like while reading.',
        outputPath: p.join(tmp.path, 'tts_voice_preview.wav'),
      );

      unawaited(GetIt.I<JustAudioService>().playFile(file.path));
    } on SherpaTtsException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offline voices',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Neural voices for read-aloud. Downloaded once, stored on '
                'this device.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ..._groupedByLanguage(_service.availableModels).entries.map(
                (entry) => ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    '${entry.key} (${entry.value.length})',
                    style: theme.textTheme.titleSmall,
                  ),
                  initiallyExpanded: entry.value.any(
                    (m) => m.id == (_activeId ?? ''),
                  ),
                  children: [
                    for (final model in entry.value) _buildModelTile(model),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Groups models by display language, preserving the catalog's
  /// language-sorted order.
  static Map<String, List<SherpaTtsModelInfo>> _groupedByLanguage(
    List<SherpaTtsModelInfo> models,
  ) {
    final groups = <String, List<SherpaTtsModelInfo>>{};
    for (final m in models) {
      groups.putIfAbsent(m.languageLabel, () => []).add(m);
    }
    return groups;
  }

  Widget _buildModelTile(SherpaTtsModelInfo model) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final download = _downloads[model.id];
    final isDownloaded = _downloadedIds.contains(model.id);
    final isActive = _activeId == model.id && isDownloaded;
    final isBusy = _busyId == model.id;

    final subtitle = [
      model.languageLabel,
      '${model.approxSizeMb.round()} MB',
      if (model.speakerCount > 0) '${model.speakerCount} voices',
      if (isActive) 'Active',
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.record_voice_over_rounded : Icons.graphic_eq,
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
              _buildActions(model, download, isDownloaded, isActive, isBusy),
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
            const SizedBox(height: 2),
            Text(
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
          ],
        ],
      ),
    );
  }

  Widget _buildActions(
    SherpaTtsModelInfo model,
    _ActiveDownload? download,
    bool isDownloaded,
    bool isActive,
    bool isBusy,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (download != null) {
      return IconButton(
        tooltip: 'Cancel download',
        icon: const Icon(Icons.close_rounded),
        onPressed: download.sub.cancel,
      );
    }

    if (!isDownloaded) {
      return IconButton(
        tooltip: 'Download',
        icon: const Icon(Icons.download_rounded),
        onPressed: () => _download(model),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Play sample',
          icon: Icon(
            Icons.play_circle_outline_rounded,
            color: isBusy ? scheme.onSurfaceVariant : scheme.primary,
          ),
          onPressed: isBusy ? null : () => _preview(model),
        ),
        if (!isActive)
          TextButton(
            onPressed: isBusy ? null : () => _activate(model),
            child: const Text('Use'),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: scheme.primary,
            ),
          ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: isBusy ? null : () => _delete(model),
        ),
      ],
    );
  }
}

class _ActiveDownload {
  _ActiveDownload(this.sub);

  final StreamSubscription<ModelDownloadProgress> sub;
  ModelDownloadStage stage = ModelDownloadStage.downloading;
  double fraction = 0;
}
