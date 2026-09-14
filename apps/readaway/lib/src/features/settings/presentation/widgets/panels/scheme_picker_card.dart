import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/theme/theme_scheme.dart';
import '../../bloc/settings/settings_bloc.dart';

/// Lets the user pick a color scheme.
///
/// Each available scheme is shown as a tappable option with a light and dark
/// swatch preview plus a checkmark for the active selection. The choice is
/// persisted through [SettingsBloc] (see `GlobalViewSettings.selectedScheme`).
class SchemePickerCard extends StatelessWidget {
  const SchemePickerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.selectedScheme !=
          curr.appSettings.globalViewSettings.selectedScheme,
      builder: (context, state) {
        final selectedId = state.appSettings.globalViewSettings.selectedScheme;
        return Column(
          children: [
            for (final scheme in ThemeSchemes.all)
              _SchemeOption(
                scheme: scheme,
                selected: scheme.id == selectedId,
                onTap: () {
                  final settings = state.appSettings;
                  context.read<SettingsBloc>().add(
                    SettingsEvent.updateAppSettings(
                      settings.copyWith(
                        globalViewSettings: settings.globalViewSettings
                            .copyWith(
                              selectedScheme: scheme.id,
                            ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SchemeOption extends StatelessWidget {
  const _SchemeOption({
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final ThemeScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schemeColors = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scheme.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SwatchStrip(colors: _previewColors(scheme.light)),
                      const SizedBox(width: 8),
                      _SwatchStrip(colors: _previewColors(scheme.dark)),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                LucideIcons.check,
                color: schemeColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Representative colors of an [AppColors] palette, used for the preview.
List<Color> _previewColors(AppColors colors) => [
  colors.scheme.primary,
  colors.scheme.secondary,
  colors.scheme.tertiary,
  colors.scheme.surface,
  colors.readerBackground,
];

class _SwatchStrip extends StatelessWidget {
  const _SwatchStrip({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        for (final color in colors)
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: outline, width: 0.5),
            ),
          ),
      ],
    );
  }
}
