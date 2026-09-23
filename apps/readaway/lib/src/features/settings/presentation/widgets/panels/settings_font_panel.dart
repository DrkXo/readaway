import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../settings/domain/entity/reader_preferences.dart';
import '../../../../settings/domain/entity/settings.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../reader_prefs_scope.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';

class SettingsFontPanel extends StatelessWidget {
  const SettingsFontPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SettingsSection(
          title: 'Typeface',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              fontFamily: null,
              fontSize: 16.0,
              minimumFontSize: 0.0,
            ),
            documentPath: path,
          ),
          rows: const [
            _FontFamilyRow(),
            _FontSizeRow(),
            _MinimumFontSizeRow(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Typography',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              defaultFont: ReaderDefaultFont.serif,
              serifFont: 'Noto Serif',
              sansSerifFont: 'Noto Sans',
              monospaceFont: 'Fira Code',
              fontWeight: 'normal',
              overrideFont: false,
            ),
            documentPath: path,
          ),
          rows: const [
            _DefaultFontRow(),
            _SerifFontRow(),
            _SansSerifFontRow(),
            _MonospaceFontRow(),
            _CjkFontRow(),
            _FontWeightRow(),
            _OverrideFontRow(),
            _UserStylesheetRow(),
          ],
        ),
        const SizedBox(height: 24),
        const SettingsSection(
          title: 'Custom fonts',
          rows: [_ManageCustomFontsRow()],
        ),
      ],
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
  const _FontFamilyRow();

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
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path) ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        // `null` in the model means "System" (platform default).
        final current = state.effectiveReaderPrefs(path).fontFamily ?? _system;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Font family',
          value: current,
          entries: entries,
          onChanged: (family) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              fontFamily: family == _system ? null : family,
            ),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _FontSizeRow extends StatelessWidget {
  const _FontSizeRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Font size',
          value: prefs.fontSize,
          min: 10,
          max: 32,
          divisions: 22,
          format: (v) => '${v.round()} px',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(fontSize: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _MinimumFontSizeRow extends StatelessWidget {
  const _MinimumFontSizeRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Minimum font size',
          value: prefs.minimumFontSize,
          min: 0,
          max: 24,
          divisions: 24,
          format: (v) => v == 0 ? 'Off' : '${v.round()} px',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(minimumFontSize: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _DefaultFontRow extends StatelessWidget {
  const _DefaultFontRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final current = state.effectiveReaderPrefs(path).defaultFont;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Default font'),
              ),
              SegmentedButton<ReaderDefaultFont>(
                segments: const [
                  ButtonSegment(
                    value: ReaderDefaultFont.serif,
                    label: Text('Serif'),
                  ),
                  ButtonSegment(
                    value: ReaderDefaultFont.sansSerif,
                    label: Text('Sans-serif'),
                  ),
                ],
                selected: {current},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  context.read<SettingsBloc>().updateReaderPrefs(
                    (p) => p.copyWith(defaultFont: s.first),
                    documentPath: path,
                  );
                },
              ),
            ],
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
  const _SerifFontRow();

  static const _builtin = [
    SettingsSelectEntry(value: 'Noto Serif', label: 'Noto Serif'),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path) ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final font = state.effectiveReaderPrefs(path).serifFont;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Serif font',
          value: font,
          entries: entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(serifFont: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _SansSerifFontRow extends StatelessWidget {
  const _SansSerifFontRow();

  static const _builtin = [
    SettingsSelectEntry(value: 'Noto Sans', label: 'Noto Sans'),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path) ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final font = state.effectiveReaderPrefs(path).sansSerifFont;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Sans-serif font',
          value: font,
          entries: entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(sansSerifFont: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _MonospaceFontRow extends StatelessWidget {
  const _MonospaceFontRow();

  static const _builtin = [
    SettingsSelectEntry(value: 'Fira Code', label: 'Fira Code'),
    SettingsSelectEntry(
      value: 'JetBrains Mono',
      label: 'JetBrains Mono',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path) ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final font = state.effectiveReaderPrefs(path).monospaceFont;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'Monospace font',
          value: font,
          entries: entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(monospaceFont: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _CjkFontRow extends StatelessWidget {
  const _CjkFontRow();

  static const _builtin = [
    SettingsSelectEntry(value: 'Source Han Sans', label: 'Source Han Sans'),
    SettingsSelectEntry(value: 'Source Han Serif', label: 'Source Han Serif'),
    SettingsSelectEntry(value: 'Noto Sans CJK SC', label: 'Noto Sans CJK SC'),
    SettingsSelectEntry(value: 'Noto Serif CJK SC', label: 'Noto Serif CJK SC'),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path) ||
          prev.appSettings.customFonts != curr.appSettings.customFonts,
      builder: (context, state) {
        final font = state.effectiveReaderPrefs(path).defaultCjkFont;
        final entries = [
          ..._builtin,
          ..._customFontEntries(state.appSettings.customFonts),
        ];
        return SettingsSelectRow<String>(
          label: 'CJK font',
          value: font,
          entries: entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(defaultCjkFont: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _UserStylesheetRow extends StatelessWidget {
  const _UserStylesheetRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final css = state.effectiveReaderPrefs(path).userStylesheet;
        return SettingsRow(
          label: 'User stylesheet',
          description: css.trim().isEmpty
              ? 'Add custom CSS applied to every book'
              : '${css.trim().split('\n').length} lines of custom CSS',
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _showStylesheetEditor(context, css, path),
        );
      },
    );
  }

  Future<void> _showStylesheetEditor(
    BuildContext context,
    String initial,
    String? path,
  ) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User stylesheet'),
        content: SizedBox(
          width: 480,
          height: 320,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'p { color: #333; }\nbody { line-height: 1.6; }',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      context.read<SettingsBloc>().updateReaderPrefs(
        (p) => p.copyWith(userStylesheet: result),
        documentPath: path,
      );
    }
  }
}

class _FontWeightRow extends StatelessWidget {
  const _FontWeightRow();

  static const _entries = [
    SettingsSelectEntry(value: 'lighter', label: 'Light'),
    SettingsSelectEntry(value: 'normal', label: 'Normal'),
    SettingsSelectEntry(value: 'bold', label: 'Bold'),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final weight = state.effectiveReaderPrefs(path).fontWeight;
        return SettingsSelectRow<String>(
          label: 'Font weight',
          value: weight,
          entries: _entries,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(fontWeight: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _OverrideFontRow extends StatelessWidget {
  const _OverrideFontRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final enabled = state.effectiveReaderPrefs(path).overrideFont;
        return SettingsSwitchRow(
          label: 'Override book fonts',
          description: 'Force your font choices on all books',
          value: enabled,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(overrideFont: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}
