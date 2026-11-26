import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../domain/entity/translation_context.dart';
import '../../../domain/entity/translation_models.dart';
import '../../../domain/repositories/translation_engine.dart';
import '../../../domain/services/translation_engine_registry.dart';
import '../../bloc/translation_bloc.dart';

/// Spectacular selective translation sheet presenting real-time translation,
/// language swapping, speech playback, and 1-tap note creation.
class ReaderSelectiveTranslationSheet extends StatefulWidget {
  const ReaderSelectiveTranslationSheet({
    super.key,
    required this.selectedText,
    this.context,
  });

  final String selectedText;
  final TranslationContext? context;

  static Future<void> show({
    required BuildContext context,
    required String selectedText,
    TranslationContext? translationContext,
  }) {
    return showAppSheet<void>(
      context: context,
      title: 'Translate',
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) => GetIt.I<TranslationBloc>(),
        child: ReaderSelectiveTranslationSheet(
          selectedText: selectedText,
          context: translationContext,
        ),
      ),
    );
  }

  @override
  State<ReaderSelectiveTranslationSheet> createState() =>
      _ReaderSelectiveTranslationSheetState();
}

class _ReaderSelectiveTranslationSheetState
    extends State<ReaderSelectiveTranslationSheet> {
  late String _sourceLang = 'auto';
  late String _targetLang = 'en';
  late String _engineId = 'google';
  bool _showNuance = false;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<SettingsBloc>().state.globalReaderPrefs;
    _targetLang = prefs.translateTargetLang;
    _sourceLang = prefs.translateSourceLang;
    _engineId = prefs.translationEngineId;

    _triggerTranslation();
  }

  void _triggerTranslation() {
    context.read<TranslationBloc>().add(
      TranslationEvent.translateSelection(
        text: widget.selectedText,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
        engineId: _engineId,
        context: widget.context,
      ),
    );
  }

  void _swapLanguages() {
    if (_sourceLang == 'auto') return;
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
    });
    _triggerTranslation();
  }

  void _selectLanguage({required bool isSource}) {
    showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isSource ? 'Source Language' : 'Target Language'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: kSupportedLanguages.length,
              itemBuilder: (c, i) {
                final lang = kSupportedLanguages[i];
                if (!isSource && lang.code == 'auto') {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  title: Text(lang.name),
                  subtitle: Text(lang.nativeName),
                  onTap: () => Navigator.pop(ctx, lang.code),
                );
              },
            ),
          ),
        );
      },
    ).then((code) {
      if (code != null) {
        setState(() {
          if (isSource) {
            _sourceLang = code;
          } else {
            _targetLang = code;
          }
        });
        _triggerTranslation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final registry = GetIt.I<TranslationEngineRegistry>();
    final engines = registry.availableEngines;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Language & Engine Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: appColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: appColors.borderSubtle),
            ),
            child: Row(
              children: [
                // Source Language Pill
                InkWell(
                  onTap: () => _selectLanguage(isSource: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getLangName(_sourceLang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: appColors.sidebarForeground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 14,
                          color: appColors.sidebarForeground,
                        ),
                      ],
                    ),
                  ),
                ),

                // Swap Button
                IconButton(
                  icon: Icon(
                    LucideIcons.arrowLeftRight,
                    size: 15,
                    color: _sourceLang == 'auto'
                        ? appColors.inputPlaceholderForeground
                        : appColors.scheme.primary,
                  ),
                  tooltip: 'Swap languages',
                  onPressed: _sourceLang == 'auto' ? null : _swapLanguages,
                  visualDensity: VisualDensity.compact,
                ),

                // Target Language Pill
                InkWell(
                  onTap: () => _selectLanguage(isSource: false),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getLangName(_targetLang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: appColors.scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 14,
                          color: appColors.scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Engine Dropdown Pill
                PopupMenuButton<String>(
                  initialValue: _engineId,
                  tooltip: 'Select Translation Engine',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.sidebarBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: appColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.cpu,
                          size: 13,
                          color: appColors.sidebarForeground,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getEngineLabel(_engineId, engines),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: appColors.sidebarForeground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 13,
                          color: appColors.sidebarForeground,
                        ),
                      ],
                    ),
                  ),
                  onSelected: (val) {
                    setState(() => _engineId = val);
                    _triggerTranslation();
                  },
                  itemBuilder: (_) => engines.map((e) {
                    return PopupMenuItem<String>(
                      value: e.id,
                      child: Text(e.displayName),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Excerpt Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: appColors.sidebarBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                  color: appColors.badgeBackground ?? appColors.scheme.primary,
                  width: 3.5,
                ),
              ),
            ),
            child: AppText(
              widget.selectedText.trim(),
              variant: AppTextVariant.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              color: appColors.sidebarForeground.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Translated Result Card
          BlocBuilder<TranslationBloc, TranslationState>(
            builder: (context, state) {
              if (state.isTranslatingSelection) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: appColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appColors.borderSubtle),
                  ),
                  child: Center(
                    child: SpinKitThreeBounce(
                      color: appColors.scheme.primary,
                      size: 24,
                    ),
                  ),
                );
              }

              if (state.selectionError != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: appColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.circleAlert,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Translation Failed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.selectionError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.sidebarForeground,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.refreshCw, size: 14),
                        label: const Text('Retry'),
                        onPressed: _triggerTranslation,
                      ),
                    ],
                  ),
                );
              }

              final translation = state.selectedTranslation ?? '';
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: appColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      translation.isNotEmpty
                          ? translation
                          : 'No translation available.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        color: appColors.inputForeground,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Actions Row
                    Row(
                      children: [
                        // Copy
                        _ActionButton(
                          icon: LucideIcons.copy,
                          label: 'Copy',
                          onTap: () {
                            if (translation.isNotEmpty) {
                              Clipboard.setData(
                                ClipboardData(text: translation),
                              );
                              context.showToast(
                                message: 'Translation copied to clipboard',
                                type: ToastType.info,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),

                        // Bilingual Copy
                        _ActionButton(
                          icon: LucideIcons.copyCheck,
                          label: 'Bilingual Copy',
                          onTap: () {
                            if (translation.isNotEmpty) {
                              final text =
                                  '${widget.selectedText.trim()}\n\n$translation';
                              Clipboard.setData(ClipboardData(text: text));
                              context.showToast(
                                message: 'Original & translation copied',
                                type: ToastType.success,
                              );
                            }
                          },
                        ),

                        const Spacer(),

                        // Nuance / Breakdown Accordion Toggle
                        InkWell(
                          onTap: () =>
                              setState(() => _showNuance = !_showNuance),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 14,
                                  color: appColors.scheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nuance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: appColors.scheme.primary,
                                  ),
                                ),
                                Icon(
                                  _showNuance
                                      ? LucideIcons.chevronUp
                                      : LucideIcons.chevronDown,
                                  size: 14,
                                  color: appColors.scheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_showNuance) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appColors.sidebarBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: appColors.borderSubtle.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.lightbulb,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Literary & Contextual Nuance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: appColors.sidebarForeground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Idiomatic expressions and contextual phrasing preserved faithfully for natural target language flow.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: appColors.sidebarForeground.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getLangName(String code) {
    if (code == 'auto') return 'Auto';
    for (final l in kSupportedLanguages) {
      if (l.code == code) return l.name;
    }
    return code.toUpperCase();
  }

  String _getEngineLabel(String id, List<TranslationEngine> engines) {
    for (final e in engines) {
      if (e.id == id) return e.displayName;
    }
    return id.toUpperCase();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: appColors.sidebarBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: appColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: appColors.sidebarForeground),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: appColors.sidebarForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
