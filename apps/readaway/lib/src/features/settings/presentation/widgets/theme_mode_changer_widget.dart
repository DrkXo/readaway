import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway/src/core/services/services.dart';

class ThemeModeChangerWidget extends StatelessWidget {
  const ThemeModeChangerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = GetIt.I.get<ThemeService>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<ThemeMode>(
              stream: themeService.themeChanges,
              initialData: themeService.currentThemeMode,
              builder: (context, snapshot) {
                final currentMode = snapshot.data ?? ThemeMode.system;
                return SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {currentMode},
                    onSelectionChanged: (selected) {
                      final mode = selected.first;
                      switch (mode) {
                        case ThemeMode.light:
                          themeService.setLightMode();
                          break;
                        case ThemeMode.dark:
                          themeService.setDarkMode();
                          break;
                        case ThemeMode.system:
                          themeService.setSystemMode();
                          break;
                      }
                    },
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
