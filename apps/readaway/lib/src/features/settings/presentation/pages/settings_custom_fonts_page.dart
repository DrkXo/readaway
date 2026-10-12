import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entity/settings.dart';
import '../bloc/settings/settings_bloc.dart';
import '../widgets/widgets.dart';

/// Management page for user-added fonts.
///
/// Lets the user pick `.ttf`/`.otf` files, which are copied into app storage
/// and registered at runtime via [FontService]. Added fonts become available
/// in the reader's font pickers.
class SettingsCustomFontsPage extends StatelessWidget {
  const SettingsCustomFontsPage({super.key});

  Future<void> _addFont(BuildContext context) async {
    final settingsBloc = context.read<SettingsBloc>();
    final fontService = GetIt.I<FontService>();

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );

    if (result.isEmpty || result.first.path == null) return;
    final path = result.first.path!;

    try {
      final font = await fontService.addFont(path);
      settingsBloc.add(
        SettingsEvent.updateAppSettings(
          (s) => s.copyWith(customFonts: [...s.customFonts, font]),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        context.showErrorToast('Failed to add font: $e');
      }
    }
  }

  Future<void> _removeFont(
    BuildContext context,
    CustomFont font,
  ) async {
    final fontService = GetIt.I<FontService>();
    final settingsBloc = context.read<SettingsBloc>();

    await fontService.removeFont(font);
    settingsBloc.add(
      SettingsEvent.updateAppSettings(
        (s) => s.copyWith(
          customFonts: s.customFonts.where((f) => f.id != font.id).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: context.appColors.readerBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsSheetHeader(
              title: 'custom fonts',
              leading: SettingsSheetBackButton(useText: true),
            ),
            Expanded(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                buildWhen: (prev, curr) =>
                    prev.appSettings.customFonts !=
                    curr.appSettings.customFonts,
                builder: (context, state) {
                  final fonts = state.appSettings.customFonts;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      SettingsSection(
                        title: 'Installed fonts',
                        rows: [
                          if (fonts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No custom fonts yet. Add a .ttf or .otf '
                                'file to use it in the reader.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            for (final font in fonts)
                              SettingsRow(
                                label: font.name,
                                description: font.path,
                                trailing: IconButton(
                                  icon: const Icon(LucideIcons.trash2),
                                  tooltip: 'Remove font',
                                  onPressed: () => _removeFont(context, font),
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      MetroPressable(
                        onTap: () => _addFont(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          color: context.appColors.buttonBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.plus,
                                size: 18,
                                color: context.appColors.buttonForeground,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'add font',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.buttonForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
