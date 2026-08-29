import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/models.dart';
import '../../../../core/services/services.dart';
import '../bloc/settings/settings_bloc.dart';
import '../widgets/widgets.dart';

/// Management page for user-added fonts.
///
/// Lets the user pick `.ttf`/`.otf` files, which are copied into app storage
/// and registered at runtime via [FontService]. Added fonts become available
/// in the reader's font pickers.
class CustomFontsPage extends StatelessWidget {
  const CustomFontsPage({super.key});

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
      final settings = settingsBloc.state.appSettings;
      settingsBloc.add(
        SettingsEvent.updateAppSettings(
          settings.copyWith(
            customFonts: [...settings.customFonts, font],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add font: $e')),
        );
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
    final settings = settingsBloc.state.appSettings;
    settingsBloc.add(
      SettingsEvent.updateAppSettings(
        settings.copyWith(
          customFonts: settings.customFonts
              .where((f) => f.id != font.id)
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header: title & close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                child: Row(
                  children: [
                    Text(
                      'Custom fonts',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Flexible(
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
                        FilledButton.icon(
                          onPressed: () => _addFont(context),
                          icon: const Icon(LucideIcons.plus),
                          label: const Text('Add font'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
