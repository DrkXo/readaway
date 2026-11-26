import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../reader/domain/entity/reader_preferences.dart';
import '../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../../settings/presentation/widgets/settings_bloc_x.dart';
import '../../../domain/entity/translation_models.dart';
import '../../bloc/translation_bloc.dart';

/// Floating minimalist HUD pill for controlling immersive reading translation.
class ReaderImmersiveTranslationBar extends StatelessWidget {
  const ReaderImmersiveTranslationBar({
    super.key,
    required this.documentPath,
    required this.bottomOffset,
  });

  final String? documentPath;
  final double bottomOffset;

  void _setMode(BuildContext context, ReaderTranslationMode mode) {
    context.read<SettingsBloc>().updateReaderPrefs(
      (p) => p.copyWith(translationMode: mode),
      documentPath: documentPath,
    );
  }

  void _selectTargetLanguage(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Target Language'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: kSupportedLanguages.length,
              itemBuilder: (c, i) {
                final lang = kSupportedLanguages[i];
                if (lang.code == 'auto') return const SizedBox.shrink();
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
      if (code != null && context.mounted) {
        context.read<SettingsBloc>().updateReaderPrefs(
          (p) => p.copyWith(translateTargetLang: code),
          documentPath: documentPath,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final settingsState = context.watch<SettingsBloc>().state;
    final prefs = settingsState.effectiveReaderPrefs(documentPath);

    if (prefs.translationMode == ReaderTranslationMode.disabled) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appColors.sidebarBackground.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: appColors.borderSubtle.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<TranslationBloc, TranslationState>(
                builder: (context, transState) {
                  final isTranslating = transState.isTranslatingChapter;
                  final progress = (transState.chapterProgress * 100).round();

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Icon / Spinner
                      if (isTranslating)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                          child: SpinKitRing(
                            color: appColors.scheme.primary,
                            size: 14,
                            lineWidth: 2,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                          child: Icon(
                            LucideIcons.languages,
                            size: 15,
                            color: appColors.scheme.primary,
                          ),
                        ),

                      // Mode Switcher Pills
                      _ModeSegmentButton(
                        label: 'Bilingual',
                        isSelected:
                            prefs.translationMode ==
                            ReaderTranslationMode.bilingualInterlinear,
                        onTap: () => _setMode(
                          context,
                          ReaderTranslationMode.bilingualInterlinear,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _ModeSegmentButton(
                        label: 'Target Only',
                        isSelected:
                            prefs.translationMode ==
                            ReaderTranslationMode.translatedOnly,
                        onTap: () => _setMode(
                          context,
                          ReaderTranslationMode.translatedOnly,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Target Language Badge
                      InkWell(
                        onTap: () => _selectTargetLanguage(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: appColors.inputBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: appColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                prefs.translateTargetLang.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: appColors.scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                LucideIcons.chevronDown,
                                size: 12,
                                color: appColors.scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isTranslating) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$progress%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: appColors.sidebarForeground.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(width: 6),

                      // Close / Turn Off Button
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 15),
                        tooltip: 'Turn off translation',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        onPressed: () => _setMode(
                          context,
                          ReaderTranslationMode.disabled,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  const _ModeSegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final primary = appColors.badgeBackground ?? appColors.scheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? appColors.scheme.onPrimary
                : appColors.sidebarForeground.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
