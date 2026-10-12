import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entity/reader_preferences.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../reader_prefs_scope.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';
import 'scheme_picker_card.dart';

class SettingsAppearancePanel extends StatelessWidget {
  const SettingsAppearancePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    final bloc = context.read<SettingsBloc>();

    void resetTheme() {
      bloc.add(
        SettingsEvent.updateAppSettings(
          (s) => s.copyWith(
            globalViewSettings: s.globalViewSettings.copyWith(
              theme: 'system',
              selectedScheme: 'token',
              uiFont: 'Madimi One',
            ),
          ),
        ),
      );
    }

    void resetDisplayAdjustment() {
      bloc.updateReaderPrefs(
        (p) => p.copyWith(
          brightnessOverlay: 0.0,
          contrastOverlay: 0.0,
        ),
        documentPath: path,
      );
    }

    void resetReading() {
      bloc.updateReaderPrefs(
        (p) => p.copyWith(selectionAnchorStyle: ReaderAnchorStyle.modernPin),
        documentPath: path,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ScopedSettingsSection(
          scopable: false,
          title: 'Theme',
          onReset: resetTheme,
          rows: const [
            _ThemeModeCard(),
            SchemePickerCard(),
            _UiFontRow(),
          ],
        ),
        const SizedBox(height: 24),
        ScopedSettingsSection(
          title: 'Display adjustment',
          onReset: resetDisplayAdjustment,
          rows: const [
            _BrightnessOverlayRow(),
            _ContrastOverlayRow(),
          ],
        ),
        const SizedBox(height: 24),
        ScopedSettingsSection(
          title: 'Reading',
          onReset: resetReading,
          rows: const [
            _SelectionAnchorStyleRow(),
          ],
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: MetroPivotControl<ThemeMode>(
            value: mode,
            size: MetroPivotControlSize.compact,
            expanded: true,
            items: const [
              MetroPivotControlItem(
                value: ThemeMode.light,
                icon: LucideIcons.sun,
                label: 'light',
              ),
              MetroPivotControlItem(
                value: ThemeMode.system,
                icon: LucideIcons.sunMoon,
                label: 'system',
              ),
              MetroPivotControlItem(
                value: ThemeMode.dark,
                icon: LucideIcons.moon,
                label: 'dark',
              ),
            ],
            onChanged: (selected) {
              context.read<SettingsBloc>().add(
                SettingsEvent.updateAppSettings(
                  (s) => s.copyWith(
                    globalViewSettings: s.globalViewSettings.copyWith(
                      theme: selected.name,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _UiFontRow extends StatelessWidget {
  const _UiFontRow();

  /// Sentinel for the "System" (platform default) choice, which maps to a
  /// null font family on the [ThemeData].
  static const _system = 'system';

  static const _builtin = [
    SettingsSelectEntry<String>(value: _system, label: 'System'),
    SettingsSelectEntry<String>(value: 'Madimi One', label: 'Madimi One'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.uiFont !=
          curr.appSettings.globalViewSettings.uiFont,
      builder: (context, state) {
        final current = state.appSettings.globalViewSettings.uiFont;
        return SettingsSelectRow<String>(
          label: 'UI font',
          description:
              'Typeface used across the app interface, not book content',
          value: current,
          entries: _builtin,
          onChanged: (uiFont) {
            context.read<SettingsBloc>().add(
              SettingsEvent.updateAppSettings(
                (s) => s.copyWith(
                  globalViewSettings: s.globalViewSettings.copyWith(
                    uiFont: uiFont,
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

class _BrightnessOverlayRow extends StatelessWidget {
  const _BrightnessOverlayRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Brightness',
          value: prefs.brightnessOverlay,
          min: 0,
          max: 0.8,
          divisions: 80,
          format: (v) => v == 0 ? 'Off' : '-${(v * 100).round()}%',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(brightnessOverlay: v),
            documentPath: path,
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
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Contrast',
          value: prefs.contrastOverlay,
          min: 0,
          max: 0.5,
          divisions: 50,
          format: (v) => v == 0 ? 'Off' : '+${(v * 100).round()}%',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(contrastOverlay: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _SelectionAnchorStyleRow extends StatelessWidget {
  const _SelectionAnchorStyleRow();

  static const _entries = [
    SettingsSelectEntry(
      value: ReaderAnchorStyle.modernPin,
      label: 'Modern pin',
    ),
    SettingsSelectEntry(
      value: ReaderAnchorStyle.lollipop,
      label: 'Lollipop caret',
    ),
    SettingsSelectEntry(
      value: ReaderAnchorStyle.minimalPill,
      label: 'Minimal pill',
    ),
    SettingsSelectEntry(
      value: ReaderAnchorStyle.classicTeardrop,
      label: 'Classic teardrop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path).selectionAnchorStyle !=
          curr.effectiveReaderPrefs(path).selectionAnchorStyle,
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSelectRow<ReaderAnchorStyle>(
          label: 'Selection handles',
          description: 'Style of start and end text selection handles',
          value: prefs.selectionAnchorStyle,
          entries: _entries,
          onChanged: (style) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(selectionAnchorStyle: style),
            documentPath: path,
          ),
        );
      },
    );
  }
}
