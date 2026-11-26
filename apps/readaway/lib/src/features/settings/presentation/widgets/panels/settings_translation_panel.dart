import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../reader/domain/entity/reader_preferences.dart';
import '../../../../translation/domain/entity/translation_models.dart';
import '../../../../translation/domain/repositories/translation_cache_repository.dart';
import '../../../../translation/domain/services/translation_engine_registry.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../reader_prefs_scope.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';

/// Settings panel for configuring translation engines, languages, immersive
/// presentation styles, and offline SQLite translation memory.
class SettingsTranslationPanel extends StatelessWidget {
  const SettingsTranslationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    final bloc = context.read<SettingsBloc>();

    void resetTranslationPrefs() {
      bloc.updateReaderPrefs(
        (p) => p.copyWith(
          translationMode: ReaderTranslationMode.disabled,
          translateTargetLang: 'en',
          translateSourceLang: 'auto',
          translationEngineId: 'google',
          translationFontScale: 0.85,
          translationShowOriginalOnTap: true,
        ),
        documentPath: path,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ScopedSettingsSection(
          title: 'Immersive Reading Presentation',
          onReset: resetTranslationPrefs,
          rows: const [
            _TranslationModeRow(),
            _TranslationFontScaleRow(),
            _ShowOriginalOnTapRow(),
          ],
        ),
        const SizedBox(height: 24),
        ScopedSettingsSection(
          title: 'Language & Translation Engine',
          onReset: resetTranslationPrefs,
          rows: const [
            _TargetLanguageRow(),
            _SourceLanguageRow(),
            _TranslationEngineRow(),
          ],
        ),
        const SizedBox(height: 24),
        ScopedSettingsSection(
          scopable: false,
          title: 'Offline Translation Memory',
          rows: const [
            _TranslationCacheMaintenanceRow(),
          ],
        ),
      ],
    );
  }
}

class _TranslationModeRow extends StatelessWidget {
  const _TranslationModeRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path).translationMode !=
          curr.effectiveReaderPrefs(path).translationMode,
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSelectRow<ReaderTranslationMode>(
          label: 'Immersive mode',
          description: 'Display style for chapter-level real-time translation.',
          value: prefs.translationMode,
          entries: const [
            SettingsSelectEntry(
              value: ReaderTranslationMode.disabled,
              label: 'Off',
            ),
            SettingsSelectEntry(
              value: ReaderTranslationMode.bilingualInterlinear,
              label: 'Bilingual Interlinear',
            ),
            SettingsSelectEntry(
              value: ReaderTranslationMode.translatedOnly,
              label: 'Target Language Only',
            ),
            SettingsSelectEntry(
              value: ReaderTranslationMode.sideBySideSpread,
              label: 'Dual Spread (Side-by-side)',
            ),
          ],
          onChanged: (mode) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(translationMode: mode),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _TranslationFontScaleRow extends StatelessWidget {
  const _TranslationFontScaleRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path).translationFontScale !=
          curr.effectiveReaderPrefs(path).translationFontScale,
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Translated font scale',
          value: prefs.translationFontScale,
          min: 0.7,
          max: 1.3,
          divisions: 12,
          format: (v) => '${(v * 100).round()}%',
          onChanged: (scale) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(translationFontScale: scale),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _ShowOriginalOnTapRow extends StatelessWidget {
  const _ShowOriginalOnTapRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path).translationShowOriginalOnTap !=
          curr.effectiveReaderPrefs(path).translationShowOriginalOnTap,
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSwitchRow(
          label: 'Tap to peek original',
          description: 'In target-only mode, tapping a sentence displays its original text.',
          value: prefs.translationShowOriginalOnTap,
          onChanged: (val) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(translationShowOriginalOnTap: val),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _TargetLanguageRow extends StatelessWidget {
  const _TargetLanguageRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path).translateTargetLang !=
          curr.effectiveReaderPrefs(path).translateTargetLang,
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        final currentCode = prefs.translateTargetLang;

        final targetEntries = kSupportedLanguages
            .where((l) => l.code != 'auto')
            .map(
              (l) => SettingsSelectEntry<String>(
                value: l.code,
                label: '${l.name} (${l.nativeName})',
              ),
            )
            .toList();

        return SettingsSelectRow<String>(
          label: 'Target language',
          description: 'Primary language for text translation.',
          value: currentCode,
          entries: targetEntries,
          onChanged: (lang) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(translateTargetLang: lang),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _SourceLanguageRow extends StatelessWidget {
  const _SourceLanguageRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path).translateSourceLang !=
          curr.effectiveReaderPrefs(path).translateSourceLang,
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        final currentCode = prefs.translateSourceLang;

        final sourceEntries = kSupportedLanguages
            .map(
              (l) => SettingsSelectEntry<String>(
                value: l.code,
                label: l.code == 'auto'
                    ? 'Auto Detect'
                    : '${l.name} (${l.nativeName})',
              ),
            )
            .toList();

        return SettingsSelectRow<String>(
          label: 'Source language',
          description: 'Original language detection.',
          value: currentCode,
          entries: sourceEntries,
          onChanged: (lang) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(translateSourceLang: lang),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _TranslationEngineRow extends StatelessWidget {
  const _TranslationEngineRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    final registry = GetIt.I.isRegistered<TranslationEngineRegistry>()
        ? GetIt.I<TranslationEngineRegistry>()
        : null;
    final engines = registry?.availableEngines ?? [];

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path).translationEngineId !=
          curr.effectiveReaderPrefs(path).translationEngineId,
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        final currentId = prefs.translationEngineId;

        final entries = engines.isNotEmpty
            ? engines
                  .map(
                    (e) => SettingsSelectEntry<String>(
                      value: e.id,
                      label: e.displayName,
                    ),
                  )
                  .toList()
            : const [
                SettingsSelectEntry(
                  value: 'google',
                  label: 'Google Translate',
                ),
                SettingsSelectEntry(
                  value: 'deepl',
                  label: 'DeepL API',
                ),
              ];

        return SettingsSelectRow<String>(
          label: 'Translation engine',
          description: 'Provider used for neural translation.',
          value: entries.any((e) => e.value == currentId)
              ? currentId
              : entries.first.value,
          entries: entries,
          onChanged: (id) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(translationEngineId: id),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _TranslationCacheMaintenanceRow extends StatelessWidget {
  const _TranslationCacheMaintenanceRow();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clear translation cache',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: appColors.sidebarForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remove all cached chapter and selection translations stored in SQLite.',
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.inputPlaceholderForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.trash2, size: 14),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(
                color: Colors.redAccent.withValues(alpha: 0.5),
              ),
            ),
            onPressed: () async {
              if (GetIt.I.isRegistered<TranslationCacheRepository>()) {
                await GetIt.I<TranslationCacheRepository>().clearAll();
              }
              if (context.mounted) {
                context.showToast(
                  message: 'Translation cache cleared successfully',
                  type: ToastType.success,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
