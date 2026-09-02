import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../primitives/reader_prefs_builder.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';
import 'settings_panel_state.dart';

class SettingsFontPanel extends StatefulWidget {
  const SettingsFontPanel({super.key, this.showScopeToggle = false});

  final bool showScopeToggle;

  @override
  State<SettingsFontPanel> createState() => _SettingsFontPanelState();
}

class _SettingsFontPanelState extends State<SettingsFontPanel>
    with SettingsPanelState {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.activeDocumentPath != curr.activeDocumentPath,
      builder: (context, state) {
        final activePath = state.activeDocumentPath;
        final showScope = widget.showScopeToggle && activePath != null;
        final scope = showScope
            ? (isGlobalMode ? SettingsScope.global : SettingsScope.perBook)
            : null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (showScope) ...[
              SettingsScopeToggle(
                isGlobalMode: isGlobalMode,
                onChanged: (v) => setState(() => isGlobalMode = v),
              ),
              const SizedBox(height: 16),
            ],
            SettingsSection(
              title: 'Typeface',
              scope: scope,
              onReset: () => resetSection(
                (p) => p.copyWith(fontFamily: null, fontSize: 16.0),
              ),
              rows: [
                _FontFamilyRow(
                  isGlobalMode: isGlobalMode,
                  activePath: activePath,
                ),
                _FontSizeRow(
                  isGlobalMode: isGlobalMode,
                  activePath: activePath,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Typography',
              scope: scope,
              onReset: () => resetSection(
                (p) => p.copyWith(
                  serifFont: 'Noto Serif',
                  sansSerifFont: 'Noto Sans',
                  monospaceFont: 'Fira Code',
                  fontWeight: 'normal',
                  overrideFont: false,
                ),
              ),
              rows: [
                _SerifFontRow(
                  isGlobalMode: isGlobalMode,
                  activePath: activePath,
                ),
                _SansSerifFontRow(
                  isGlobalMode: isGlobalMode,
                  activePath: activePath,
                ),
                _MonospaceFontRow(
                  isGlobalMode: isGlobalMode,
                  activePath: activePath,
                ),
                _FontWeightRow(
                  isGlobalMode: isGlobalMode,
                  activePath: activePath,
                ),
                _OverrideFontRow(
                  isGlobalMode: isGlobalMode,
                  activePath: activePath,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SettingsSection(
              title: 'Custom fonts',
              rows: [_ManageCustomFontsRow()],
            ),
          ],
        );
      },
    );
  }
}

class _ManageCustomFontsRow extends StatelessWidget {
  const _ManageCustomFontsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final count = state.appSettings.customFonts.length;
        return SettingsRow(
          label: 'Manage custom fonts',
          description: count == 0
              ? 'Add .ttf or .otf fonts'
              : '$count installed',
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => context.pushNamed(appRoutes.customFonts.name),
        );
      },
    );
  }
}

class _FontFamilyRow extends StatelessWidget {
  const _FontFamilyRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  /// Sentinel for the "System" (platform default) choice. A non-null value is
  /// required because `PopupMenuButton` treats a `PopupMenuItem` with a null
  /// value as non-selectable, which would make "System" unselectable.
  static const _system = 'system';

  static const _builtin = [
    SettingsSelectEntry<String>(value: _system, label: 'System'),
    SettingsSelectEntry<String>(value: 'Noto Serif', label: 'Noto Serif'),
    SettingsSelectEntry<String>(value: 'Noto Sans', label: 'Noto Sans'),
    SettingsSelectEntry<String>(value: 'Fira Code', label: 'Fira Code'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).fontFamily !=
              curr.resolvedReaderPrefs(activePath).fontFamily ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        // `null` in the model means "System" (platform default).
        final current =
            state.resolvedReaderPrefs(activePath).fontFamily ?? _system;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Font family',
          value: current,
          entries: entries,
          onChanged: (family) => context.read<SettingsBloc>().updateReaderPrefs(
            state: state,
            activePath: activePath,
            isGlobalMode: isGlobalMode,
            update: (p) => p.copyWith(
              fontFamily: family == _system ? null : family,
            ),
          ),
        );
      },
    );
  }
}

class _FontSizeRow extends StatelessWidget {
  const _FontSizeRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return ReaderPrefsBuilder(
      activePath: activePath,
      builder: (context, prefs) {
        return SettingsSliderRow(
          label: 'Font size',
          value: prefs.fontSize,
          min: 10,
          max: 32,
          divisions: 22,
          format: (v) => '${v.round()} px',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            state: context.read<SettingsBloc>().state,
            activePath: activePath,
            isGlobalMode: isGlobalMode,
            update: (p) => p.copyWith(fontSize: v),
          ),
        );
      },
    );
  }
}

/// Builds dropdown entries for the user's installed custom fonts.
List<SettingsSelectEntry<String>> _customFontEntries(
  List<CustomFont> fonts,
) {
  return [
    for (final font in fonts)
      SettingsSelectEntry<String>(value: font.name, label: font.name),
  ];
}

class _SerifFontRow extends StatelessWidget {
  const _SerifFontRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  static const _builtin = [
    SettingsSelectEntry(value: 'Noto Serif', label: 'Noto Serif'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).serifFont !=
              curr.resolvedReaderPrefs(activePath).serifFont ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final font = state.resolvedReaderPrefs(activePath).serifFont;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Serif font',
          value: font,
          entries: entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            state: state,
            activePath: activePath,
            isGlobalMode: isGlobalMode,
            update: (p) => p.copyWith(serifFont: v),
          ),
        );
      },
    );
  }
}

class _SansSerifFontRow extends StatelessWidget {
  const _SansSerifFontRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  static const _builtin = [
    SettingsSelectEntry(value: 'Noto Sans', label: 'Noto Sans'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).sansSerifFont !=
              curr.resolvedReaderPrefs(activePath).sansSerifFont ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final font = state.resolvedReaderPrefs(activePath).sansSerifFont;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Sans-serif font',
          value: font,
          entries: entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            state: state,
            activePath: activePath,
            isGlobalMode: isGlobalMode,
            update: (p) => p.copyWith(sansSerifFont: v),
          ),
        );
      },
    );
  }
}

class _MonospaceFontRow extends StatelessWidget {
  const _MonospaceFontRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  static const _builtin = [
    SettingsSelectEntry(value: 'Fira Code', label: 'Fira Code'),
    SettingsSelectEntry(
      value: 'JetBrains Mono',
      label: 'JetBrains Mono',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).monospaceFont !=
              curr.resolvedReaderPrefs(activePath).monospaceFont ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final font = state.resolvedReaderPrefs(activePath).monospaceFont;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Monospace font',
          value: font,
          entries: entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            state: state,
            activePath: activePath,
            isGlobalMode: isGlobalMode,
            update: (p) => p.copyWith(monospaceFont: v),
          ),
        );
      },
    );
  }
}

class _FontWeightRow extends StatelessWidget {
  const _FontWeightRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  static const _entries = [
    SettingsSelectEntry(value: 'lighter', label: 'Light'),
    SettingsSelectEntry(value: 'normal', label: 'Normal'),
    SettingsSelectEntry(value: 'bold', label: 'Bold'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).fontWeight !=
          curr.resolvedReaderPrefs(activePath).fontWeight,
      builder: (context, state) {
        final weight = state.resolvedReaderPrefs(activePath).fontWeight;
        return SettingsSelectRow<String>(
          label: 'Font weight',
          value: weight,
          entries: _entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            state: state,
            activePath: activePath,
            isGlobalMode: isGlobalMode,
            update: (p) => p.copyWith(fontWeight: v),
          ),
        );
      },
    );
  }
}

class _OverrideFontRow extends StatelessWidget {
  const _OverrideFontRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).overrideFont !=
          curr.resolvedReaderPrefs(activePath).overrideFont,
      builder: (context, state) {
        final enabled = state.resolvedReaderPrefs(activePath).overrideFont;
        return SettingsSwitchRow(
          label: 'Override book fonts',
          description: 'Force your font choices on all books',
          value: enabled,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            state: state,
            activePath: activePath,
            isGlobalMode: isGlobalMode,
            update: (p) => p.copyWith(overrideFont: v),
          ),
        );
      },
    );
  }
}
