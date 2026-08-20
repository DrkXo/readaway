import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/reader_preferences.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final prefs = state.globalReaderPrefs;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _ThemeModeSection(prefs: prefs),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection({required this.prefs});

  final ReaderPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: context.appColors.shadowSm,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ReaderThemeMode>(
            segments: const [
              ButtonSegment(
                value: ReaderThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ReaderThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ReaderThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (selected) {
              final mode = selected.first;
              context.read<SettingsBloc>().add(
                SettingsEvent.setGlobalReaderPref(
                  prefs.copyWith(themeMode: mode),
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
