import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bloc/settings_bloc.dart';
import '../widgets.dart';

class AppearancePanel extends StatelessWidget {
  const AppearancePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        void resetTheme() {
          final settings = state.appSettings;
          context.read<SettingsBloc>().add(
            SettingsEvent.updateAppSettings(
              settings.copyWith(
                globalViewSettings: settings.globalViewSettings.copyWith(
                  theme: 'system',
                ),
              ),
            ),
          );
        }

        void resetDisplayAdjustment() {
          context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              state.globalReaderPrefs.copyWith(
                brightnessOverlay: 0.0,
                contrastOverlay: 0.0,
              ),
            ),
          );
        }

        void resetReading() {
          final settings = state.appSettings;
          context.read<SettingsBloc>().add(
            SettingsEvent.updateAppSettings(
              settings.copyWith(
                globalViewSettings: settings.globalViewSettings.copyWith(
                  highlightOpacity: 0.3,
                  invertImgColorInDark: true,
                  applyThemeToPdf: true,
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SettingsSection(
              title: 'Theme',
              onReset: resetTheme,
              rows: const [_ThemeModeCard()],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Display adjustment',
              onReset: resetDisplayAdjustment,
              rows: const [
                _BrightnessOverlayRow(),
                _ContrastOverlayRow(),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Reading',
              onReset: resetReading,
              rows: const [
                _HighlightOpacityRow(),
                _InvertImgColorRow(),
                _ApplyThemeToPdfRow(),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.theme !=
          curr.appSettings.globalViewSettings.theme,
      builder: (context, state) {
        final saved = state.appSettings.globalViewSettings.theme;
        final mode = switch (saved) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(LucideIcons.sun),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(LucideIcons.sunMoon),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(LucideIcons.moon),
                  label: Text('Dark'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selected) {
                final settings = state.appSettings;
                context.read<SettingsBloc>().add(
                  SettingsEvent.updateAppSettings(
                    settings.copyWith(
                      globalViewSettings: settings.globalViewSettings.copyWith(
                        theme: selected.first.name,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BrightnessOverlayRow extends StatelessWidget {
  const _BrightnessOverlayRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.brightnessOverlay !=
          curr.globalReaderPrefs.brightnessOverlay,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        return SettingsSliderRow(
          label: 'Brightness',
          value: prefs.brightnessOverlay,
          min: 0,
          max: 0.8,
          divisions: 80,
          format: (v) => v == 0 ? 'Off' : '-${(v * 100).round()}%',
          onChanged: (v) => context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              prefs.copyWith(brightnessOverlay: v),
            ),
          ),
        );
      },
    );
  }
}

class _ContrastOverlayRow extends StatelessWidget {
  const _ContrastOverlayRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.contrastOverlay !=
          curr.globalReaderPrefs.contrastOverlay,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        return SettingsSliderRow(
          label: 'Contrast',
          value: prefs.contrastOverlay,
          min: 0,
          max: 0.5,
          divisions: 50,
          format: (v) => v == 0 ? 'Off' : '+${(v * 100).round()}%',
          onChanged: (v) => context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              prefs.copyWith(contrastOverlay: v),
            ),
          ),
        );
      },
    );
  }
}

class _HighlightOpacityRow extends StatelessWidget {
  const _HighlightOpacityRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.highlightOpacity !=
          curr.appSettings.globalViewSettings.highlightOpacity,
      builder: (context, state) {
        final opacity = state.appSettings.globalViewSettings.highlightOpacity;
        return SettingsSliderRow(
          label: 'Highlight opacity',
          value: opacity,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          format: (v) => '${(v * 100).round()}%',
          onChanged: (v) {
            final settings = state.appSettings;
            context.read<SettingsBloc>().add(
              SettingsEvent.updateAppSettings(
                settings.copyWith(
                  globalViewSettings: settings.globalViewSettings.copyWith(
                    highlightOpacity: v,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InvertImgColorRow extends StatelessWidget {
  const _InvertImgColorRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.invertImgColorInDark !=
          curr.appSettings.globalViewSettings.invertImgColorInDark,
      builder: (context, state) {
        final enabled =
            state.appSettings.globalViewSettings.invertImgColorInDark;
        return SettingsSwitchRow(
          label: 'Invert images in dark mode',
          value: enabled,
          onChanged: (v) {
            final settings = state.appSettings;
            context.read<SettingsBloc>().add(
              SettingsEvent.updateAppSettings(
                settings.copyWith(
                  globalViewSettings: settings.globalViewSettings.copyWith(
                    invertImgColorInDark: v,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ApplyThemeToPdfRow extends StatelessWidget {
  const _ApplyThemeToPdfRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.applyThemeToPdf !=
          curr.appSettings.globalViewSettings.applyThemeToPdf,
      builder: (context, state) {
        final enabled = state.appSettings.globalViewSettings.applyThemeToPdf;
        return SettingsSwitchRow(
          label: 'Apply theme to PDF',
          description: 'Use app theme colors when rendering PDF books',
          value: enabled,
          onChanged: (v) {
            final settings = state.appSettings;
            context.read<SettingsBloc>().add(
              SettingsEvent.updateAppSettings(
                settings.copyWith(
                  globalViewSettings: settings.globalViewSettings.copyWith(
                    applyThemeToPdf: v,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
