import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/widgets/core_widgets.dart';
import '../../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../../../settings/presentation/widgets/settings_bloc_x.dart';

/// Brightness quick view with overlay dimming slider and theme switcher.
class ReaderBrightnessQuickView extends StatelessWidget {
  const ReaderBrightnessQuickView({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  void _updateBrightness(
    BuildContext context,
    double newBrightness,
  ) {
    context.read<SettingsBloc>().updateReaderPrefs(
      (p) => p.copyWith(brightnessOverlay: newBrightness),
    );
  }

  void _updateTheme(
    BuildContext context,
    SettingsState settingsState,
    String theme,
  ) {
    final settings = settingsState.appSettings;
    context.read<SettingsBloc>().add(
      SettingsEvent.updateAppSettings(
        settings.copyWith(
          globalViewSettings: settings.globalViewSettings.copyWith(
            theme: theme,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.brightnessOverlay !=
              curr.globalReaderPrefs.brightnessOverlay ||
          prev.appSettings.globalViewSettings.theme !=
              curr.appSettings.globalViewSettings.theme,
      builder: (context, settingsState) {
        final currentTheme = settingsState.appSettings.globalViewSettings.theme;
        final prefs = settingsState.globalReaderPrefs;
        final brightnessOverlay = prefs.brightnessOverlay;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    LucideIcons.sunMedium,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Display Brightness',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (brightnessOverlay > 0.0)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _updateBrightness(context, 0.0),
                      child: const Text('Reset'),
                    ),
                  Text(
                    brightnessOverlay == 0.0
                        ? '100%'
                        : '-${(brightnessOverlay * 100).round()}%',
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

              // Slider row: SunDim -> Slider -> SunMedium
              Row(
                children: [
                  Icon(
                    LucideIcons.sunDim,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppSlider(
                      value: brightnessOverlay,
                      min: 0.0,
                      max: 0.8,
                      divisions: 80,
                      compact: true,
                      onChanged: (v) => _updateBrightness(context, v),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.sunMedium,
                    size: 20,
                    color: scheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick Theme Mode Segmented Controls
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'light',
                      icon: Icon(LucideIcons.sun, size: 14),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: 'system',
                      icon: Icon(LucideIcons.sunMoon, size: 14),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      icon: Icon(LucideIcons.moon, size: 14),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {
                    switch (currentTheme) {
                      'light' => 'light',
                      'dark' => 'dark',
                      _ => 'system',
                    },
                  },
                  onSelectionChanged: (selected) {
                    _updateTheme(context, settingsState, selected.first);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
