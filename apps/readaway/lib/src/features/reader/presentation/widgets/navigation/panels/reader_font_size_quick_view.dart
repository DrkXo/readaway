import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/widgets/core_widgets.dart';
import '../../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../../../settings/presentation/widgets/settings_bloc_x.dart';
import '../../../bloc/reader_bloc.dart';

/// Font size quick view with steppers, slider, and preset scale chips.
class ReaderFontSizeQuickView extends StatelessWidget {
  const ReaderFontSizeQuickView({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;
  static const double defaultFontSize = 18.0;

  void _updateFontSize(
    BuildContext context,
    SettingsState settingsState,
    String? fileName,
    double newSize,
  ) {
    context.read<SettingsBloc>().updateReaderPrefs(
      state: settingsState,
      activePath: fileName,
      isGlobalMode: false,
      update: (p) => p.copyWith(fontSize: newSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final readerState = context.read<ReaderBloc>().state;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(readerState.fileName).fontSize !=
          curr.resolvedReaderPrefs(readerState.fileName).fontSize,
      builder: (context, settingsState) {
        final prefs = settingsState.resolvedReaderPrefs(readerState.fileName);
        final fontSize = prefs.fontSize;

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
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Font Size',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if ((fontSize - defaultFontSize).abs() > 0.5)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _updateFontSize(
                        context,
                        settingsState,
                        readerState.fileName,
                        defaultFontSize,
                      ),
                      child: const Text('Reset'),
                    ),
                  Text(
                    '${fontSize.round()} px',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: LucideIcons.x,
                    tooltip: 'Close panel',
                    size: AppIconButtonSize.small,
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Stepper & Slider row: [ - ] ===Slider=== [ + ]
              Row(
                children: [
                  AppIconButton(
                    icon: LucideIcons.minus,
                    tooltip: 'Decrease font size',
                    size: AppIconButtonSize.small,
                    onPressed: fontSize > 10
                        ? () => _updateFontSize(
                            context,
                            settingsState,
                            readerState.fileName,
                            fontSize - 1,
                          )
                        : null,
                  ),
                  Expanded(
                    child: AppSlider(
                      value: fontSize.clamp(10.0, 32.0),
                      min: 10,
                      max: 32,
                      divisions: 22,
                      compact: true,
                      onChanged: (v) => _updateFontSize(
                        context,
                        settingsState,
                        readerState.fileName,
                        v,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: LucideIcons.plus,
                    tooltip: 'Increase font size',
                    size: AppIconButtonSize.small,
                    onPressed: fontSize < 32
                        ? () => _updateFontSize(
                            context,
                            settingsState,
                            readerState.fileName,
                            fontSize + 1,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Preset Size Chips
              Wrap(
                spacing: 8,
                children: [14.0, 16.0, 18.0, 20.0, 24.0].map((size) {
                  final isSelected = (fontSize - size).abs() < 0.5;
                  return ChoiceChip(
                    label: Text('${size.round()} px'),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _updateFontSize(
                      context,
                      settingsState,
                      readerState.fileName,
                      size,
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
