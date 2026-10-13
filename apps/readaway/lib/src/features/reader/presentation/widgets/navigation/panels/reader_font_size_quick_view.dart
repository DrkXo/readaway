import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/theme/theme.dart';
import '../../../../../../core/widgets/core_widgets.dart';
import '../../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../../../settings/presentation/widgets/settings_bloc_x.dart';

/// Font size quick view with steppers, slider, and flat Metro preset scale tiles.
class ReaderFontSizeQuickView extends StatelessWidget {
  const ReaderFontSizeQuickView({
    super.key,
    required this.onClose,
    this.documentPath,
  });

  final VoidCallback onClose;
  final String? documentPath;
  static const double defaultFontSize = 18.0;

  void _updateFontSize(
    BuildContext context,
    double newSize,
  ) {
    context.read<SettingsBloc>().updateReaderPrefsWithinScope(
      (p) => p.copyWith(fontSize: newSize),
      documentPath: documentPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) {
        final before = prev.effectiveReaderPrefs(documentPath);
        final after = curr.effectiveReaderPrefs(documentPath);
        return before.fontSize != after.fontSize ||
            before.overrideLayout != after.overrideLayout;
      },
      builder: (context, settingsState) {
        final prefs = settingsState.effectiveReaderPrefs(documentPath);
        final fontSize = prefs.fontSize;
        // Mirrors the Font tab: the size only overrides the book while
        // "Override book layout" is on.
        final enabled = prefs.overrideLayout;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    LucideIcons.type,
                    size: 16,
                    color: appColors.buttonBackground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'font size',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: appColors.readerForeground,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  if ((fontSize - defaultFontSize).abs() > 0.5)
                    MetroPressable(
                      enabled: enabled,
                      onTap: enabled
                          ? () => _updateFontSize(
                              context,
                              defaultFontSize,
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'reset',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: enabled
                                ? appColors.buttonBackground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.38,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  Text(
                    '${fontSize.round()} px',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: appColors.readerForeground.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Close panel',
                    child: Semantics(
                      label: 'Close panel',
                      button: true,
                      child: MetroPressable(
                        onTap: onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: appColors.readerForeground.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Stepper & Slider row: [ - ] ===Slider=== [ + ]
              Row(
                children: [
                  Tooltip(
                    message: 'Decrease font size',
                    child: Semantics(
                      label: 'Decrease font size',
                      button: true,
                      child: MetroPressable(
                        enabled: enabled && fontSize > 10,
                        onTap: enabled && fontSize > 10
                            ? () => _updateFontSize(
                                context,
                                fontSize - 1,
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            LucideIcons.minus,
                            size: 16,
                            color: (enabled && fontSize > 10)
                                ? appColors.readerForeground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AppSlider(
                      value: fontSize.clamp(10.0, 32.0),
                      min: 10,
                      max: 32,
                      divisions: 22,
                      compact: true,
                      enabled: enabled,
                      onChanged: (v) => _updateFontSize(
                        context,
                        v,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Increase font size',
                    child: Semantics(
                      label: 'Increase font size',
                      button: true,
                      child: MetroPressable(
                        enabled: enabled && fontSize < 32,
                        onTap: enabled && fontSize < 32
                            ? () => _updateFontSize(
                                context,
                                fontSize + 1,
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: (enabled && fontSize < 32)
                                ? appColors.readerForeground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Flat Metro Preset Size Tiles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [14.0, 16.0, 18.0, 20.0, 24.0].map((size) {
                  final isSelected = (fontSize - size).abs() < 0.5;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: MetroPressable(
                        enabled: enabled,
                        onTap: enabled
                            ? () => _updateFontSize(
                                context,
                                size,
                              )
                            : null,
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? appColors.buttonBackground
                                : appColors.editorWidgetBackground,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: isSelected
                                  ? appColors.buttonBackground
                                  : appColors.borderSubtle,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${size.round()} px',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? appColors.buttonForeground
                                  : (enabled
                                        ? appColors.readerForeground
                                        : appColors.readerForeground.withValues(
                                            alpha: 0.38,
                                          )),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
