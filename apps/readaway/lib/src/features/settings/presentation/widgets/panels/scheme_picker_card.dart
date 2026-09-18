import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/theme/theme_scheme.dart';
import '../../bloc/settings/settings_bloc.dart';

/// Lets the user pick a color scheme.
///
/// An expandable row that shows the active scheme with light/dark swatch
/// previews; expanding it reveals every scheme as a full-width tappable row
/// with a checkmark on the current selection.
class SchemePickerCard extends StatefulWidget {
  const SchemePickerCard({super.key});

  @override
  State<SchemePickerCard> createState() => _SchemePickerCardState();
}

class _SchemePickerCardState extends State<SchemePickerCard> {
  final _controller = ExpansibleController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.selectedScheme !=
          curr.appSettings.globalViewSettings.selectedScheme,
      builder: (context, state) {
        final selectedId = state.appSettings.globalViewSettings.selectedScheme;
        final selected = ThemeSchemes.byId(selectedId);
        final colorScheme = Theme.of(context).colorScheme;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);

        return ExpansionTile(
          controller: _controller,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: colorScheme.onSurfaceVariant,
          shape: const Border(),
          collapsedShape: const Border(),
          title: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(selected.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.name,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SwatchStrip(colors: _previewColors(selected.light)),
                    const SizedBox(width: 8),
                    _SwatchStrip(colors: _previewColors(selected.dark)),
                  ],
                ),
              ],
            ),
          ),
          children: [
            for (final (index, scheme) in ThemeSchemes.all.indexed) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              _SchemeOption(
                scheme: scheme,
                selected: scheme.id == selectedId,
                onTap: () {
                  _selectScheme(context, scheme.id);
                  _controller.collapse();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  void _selectScheme(BuildContext context, String schemeId) {
    final settings = context.read<SettingsBloc>().state.appSettings;
    context.read<SettingsBloc>().add(
      SettingsEvent.updateAppSettings(
        settings.copyWith(
          globalViewSettings: settings.globalViewSettings.copyWith(
            selectedScheme: schemeId,
          ),
        ),
      ),
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
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  LucideIcons.check,
                  color: schemeColors.primary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<Color> _previewColors(VsCodeTheme theme) => [
  theme.badgeBackground ?? theme.scheme.primary,
  theme.scheme.secondary,
  theme.sheetBackground,
  theme.readerBackground,
  theme.readerForeground,
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
