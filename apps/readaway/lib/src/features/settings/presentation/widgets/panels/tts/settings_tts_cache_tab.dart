import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/services/services.dart';
import '../../../../../../core/widgets/core_widgets.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../../bloc/tts_library/tts_library_bloc.dart';
import '../../reader_prefs_scope.dart';
import '../../widgets.dart';

/// Formats raw byte count into human-readable size string.
String formatStorageBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// TTS audio cache inspection, cleanup, and policy settings.
class SettingsTtsCacheTab extends StatefulWidget {
  const SettingsTtsCacheTab({super.key});

  @override
  State<SettingsTtsCacheTab> createState() => _SettingsTtsCacheTabState();
}

class _SettingsTtsCacheTabState extends State<SettingsTtsCacheTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bookPath = context.readerPrefsDocumentPath();
      context.read<TtsLibraryBloc>().add(
        TtsLibraryEvent.loadCacheSize(bookPath: bookPath),
      );
    });
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all TTS cache?'),
        content: const Text(
          'This will permanently delete all synthesized chapter audio from disk. '
          'Downloaded voice models will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TtsLibraryBloc>().add(const TtsLibraryEvent.clearAllCache());
    }
  }

  Future<void> _confirmClearBook(BuildContext context, String bookPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear book audio cache?'),
        content: const Text(
          'This will remove all synthesized audio chunks for this book. '
          'Audio will be synthesized again when played.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TtsLibraryBloc>().add(
        TtsLibraryEvent.clearBookCache(bookPath),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookPath = context.readerPrefsDocumentPath();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<TtsLibraryBloc, TtsLibraryState>(
      buildWhen: (prev, curr) =>
          prev.totalCacheSizeBytes != curr.totalCacheSizeBytes ||
          prev.bookCacheSizeBytes != curr.bookCacheSizeBytes ||
          prev.isLoadingCacheSize != curr.isLoadingCacheSize ||
          prev.isClearingCache != curr.isClearingCache,
      builder: (context, libState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (prev, curr) =>
              prev.appSettings.globalViewSettings !=
              curr.appSettings.globalViewSettings,
          builder: (context, settingsState) {
            final gvs = settingsState.appSettings.globalViewSettings;
            final totalBytes = libState.totalCacheSizeBytes ?? 0;
            final bookBytes = libState.bookCacheSizeBytes ?? 0;
            final hasBookCache = bookPath != null && bookBytes > 0;
            final hasTotalCache = totalBytes > 0;

            final totalSizeWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (libState.isLoadingCacheSize)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    formatStorageBytes(totalBytes),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  tooltip: 'Refresh cache size',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      libState.isLoadingCacheSize || libState.isClearingCache
                      ? null
                      : () => context.read<TtsLibraryBloc>().add(
                          TtsLibraryEvent.loadCacheSize(bookPath: bookPath),
                        ),
                ),
              ],
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                ScopedSettingsSection(
                  scopable: false,
                  title: 'Audio Cache',
                  rows: [
                    SettingsRow(
                      label: 'Total audio cache',
                      description: 'Pre-rendered chapter audio on device',
                      trailing: totalSizeWidget,
                    ),
                    if (bookPath != null)
                      SettingsRow(
                        label: 'Current book cache',
                        description: 'Audio synthesized for this book',
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            formatStorageBytes(bookBytes),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    if (hasBookCache)
                      SettingsRow(
                        label: 'Clear this book\'s cache',
                        description:
                            'Remove cached chapters for this book only',
                        trailing: IconButton(
                          icon: Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: scheme.error,
                          ),
                          tooltip: 'Clear book cache',
                          onPressed: libState.isClearingCache
                              ? null
                              : () => _confirmClearBook(context, bookPath),
                        ),
                        onTap: libState.isClearingCache
                            ? null
                            : () => _confirmClearBook(context, bookPath),
                      ),
                    SettingsRow(
                      label: 'Clear all TTS cache',
                      description: hasTotalCache
                          ? 'Delete all cached chapters across all books'
                          : 'No cached audio on device',
                      trailing: IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: hasTotalCache ? scheme.error : scheme.outline,
                        ),
                        tooltip: 'Clear all cache',
                        onPressed: hasTotalCache && !libState.isClearingCache
                            ? () => _confirmClearAll(context)
                            : null,
                      ),
                      onTap: hasTotalCache && !libState.isClearingCache
                          ? () => _confirmClearAll(context)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ScopedSettingsSection(
                  scopable: false,
                  title: 'Cache Policy',
                  rows: [
                    SettingsSelectRow<int>(
                      label: 'Maximum cache size',
                      description: 'Oldest chapter audio is evicted when limit is reached',
                      value: gvs.ttsMaxCacheSizeMb,
                      entries: const [
                        SettingsSelectEntry(value: 100, label: '100 MB'),
                        SettingsSelectEntry(value: 250, label: '250 MB'),
                        SettingsSelectEntry(
                          value: 500,
                          label: '500 MB (Default)',
                        ),
                        SettingsSelectEntry(value: 1024, label: '1 GB'),
                        SettingsSelectEntry(value: 2048, label: '2 GB'),
                        SettingsSelectEntry(value: 0, label: 'Unlimited'),
                      ],
                      onChanged: (limit) {
                        final updated = settingsState.appSettings.copyWith(
                          globalViewSettings: gvs.copyWith(
                            ttsMaxCacheSizeMb: limit,
                          ),
                        );
                        context.read<SettingsBloc>().add(
                          SettingsEvent.updateAppSettings(updated),
                        );
                        if (limit > 0) {
                          GetIt.I
                              .get<TtsChapterCacheService>()
                              .enforceCacheLimit(limit * 1024 * 1024);
                          context.read<TtsLibraryBloc>().add(
                            TtsLibraryEvent.loadCacheSize(
                              bookPath: bookPath,
                            ),
                          );
                        }
                      },
                    ),
                    SettingsSwitchRow(
                      label: 'Pre-cache next chapter',
                      description: 'Synthesize upcoming chapter in the background for continuous playback',
                      value: gvs.ttsPrecacheNextChapter,
                      onChanged: (val) {
                        final updated = settingsState.appSettings.copyWith(
                          globalViewSettings: gvs.copyWith(
                            ttsPrecacheNextChapter: val,
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
      },
    );
  }
}
