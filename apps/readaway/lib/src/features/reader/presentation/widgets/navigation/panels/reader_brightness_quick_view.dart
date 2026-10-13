import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/theme/theme.dart';
import '../../../../../../core/widgets/core_widgets.dart';
import '../../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../../../settings/presentation/widgets/settings_bloc_x.dart';

/// Brightness quick view with overlay dimming slider and Metro theme switcher.
class ReaderBrightnessQuickView extends StatelessWidget {
  const ReaderBrightnessQuickView({
    super.key,
    required this.onClose,
    this.documentPath,
  });

  final VoidCallback onClose;
  final String? documentPath;

  void _updateBrightness(
    BuildContext context,
    double newBrightness,
  ) {
    context.read<SettingsBloc>().updateReaderPrefsWithinScope(
      (p) => p.copyWith(brightnessOverlay: newBrightness),
      documentPath: documentPath,
    );
  }

  void _updateTheme(
    BuildContext context,
    String theme,
  ) {
    context.read<SettingsBloc>().add(
      SettingsEvent.updateAppSettings(
        (s) => s.copyWith(
          globalViewSettings: s.globalViewSettings.copyWith(
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
    final appColors = context.appColors;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(documentPath).brightnessOverlay !=
              curr.effectiveReaderPrefs(documentPath).brightnessOverlay ||
          prev.appSettings.globalViewSettings.theme !=
              curr.appSettings.globalViewSettings.theme,
      builder: (context, settingsState) {
        final currentTheme = settingsState.appSettings.globalViewSettings.theme;
        final prefs = settingsState.effectiveReaderPrefs(documentPath);
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
                    color: appColors.buttonBackground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'display brightness',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: appColors.readerForeground,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  if (brightnessOverlay > 0.0)
                    MetroPressable(
                      onTap: () => _updateBrightness(context, 0.0),
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
                            color: appColors.buttonBackground,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    brightnessOverlay == 0.0
                        ? '100%'
                        : '-${(brightnessOverlay * 100).round()}%',
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
                    color: appColors.buttonBackground,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Metro Theme Mode Segmented Controls
              SizedBox(
                width: double.infinity,
                child: MetroPivotControl<String>(
                  style: MetroPivotControlStyle.flatTiles,
                  size: MetroPivotControlSize.compact,
                  expanded: true,
                  value: switch (currentTheme) {
                    'light' => 'light',
                    'dark' => 'dark',
                    _ => 'system',
                  },
                  items: const [
                    MetroPivotControlItem(
                      value: 'light',
                      label: 'light',
                      icon: LucideIcons.sun,
                    ),
                    MetroPivotControlItem(
                      value: 'system',
                      label: 'system',
                      icon: LucideIcons.sunMoon,
                    ),
                    MetroPivotControlItem(
                      value: 'dark',
                      label: 'dark',
                      icon: LucideIcons.moon,
                    ),
                  ],
                  onChanged: (theme) => _updateTheme(context, theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
