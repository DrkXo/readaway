import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/settings/settings_bloc.dart';
import '../../reader_prefs_scope.dart';
import '../../settings_bloc_x.dart';
import '../../widgets.dart';

/// Margins and layout override settings for the reader.
class SettingsLayoutMarginsSection extends StatelessWidget {
  const SettingsLayoutMarginsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScopedSettingsSection(
          title: 'Book layout',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(overrideLayout: true),
            documentPath: path,
          ),
          rows: const [
            _OverrideLayoutRow(),
          ],
        ),
        const SizedBox(height: 24),
        ScopedSettingsSection(
          title: 'Page margins',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              marginHorizontal: 16,
              marginTop: 16,
              marginBottom: 16,
            ),
            documentPath: path,
          ),
          rows: const [
            _MarginPresetRow(),
            _MarginSliderRow(),
          ],
        ),
      ],
    );
  }
}

/// Whether the reader's layout settings replace the book's own styling.
///
/// While this is off, the Paragraph and Text groups cannot take effect, so
/// their rows are shown disabled.
class _OverrideLayoutRow extends StatelessWidget {
  const _OverrideLayoutRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final override = state.effectiveReaderPrefs(path).overrideLayout;
        return SettingsSwitchRow(
          label: 'Override book layout',
          description:
              'Apply your spacing and alignment over the book\'s own styling. '
              'Turn off to respect the book\'s layout.',
          value: override,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(overrideLayout: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _MarginPresetRow extends StatelessWidget {
  const _MarginPresetRow();

  static const _presets = [
    (value: 8.0, label: 'Compact'),
    (value: 16.0, label: 'Normal'),
    (value: 24.0, label: 'Wide'),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final current = state.effectiveReaderPrefs(path).marginHorizontal;
        final selected = _presets
            .where((p) => p.value == current)
            .map((p) => p.value)
            .toSet();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<double>(
            segments: [
              for (final p in _presets)
                ButtonSegment(value: p.value, label: Text(p.label)),
            ],
            selected: selected,
            emptySelectionAllowed: true,
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(
                  marginHorizontal: s.first,
                  marginTop: s.first,
                  marginBottom: s.first,
                ),
                documentPath: path,
              );
            },
          ),
        );
      },
    );
  }
}

class _MarginSliderRow extends StatelessWidget {
  const _MarginSliderRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return Column(
          children: [
            SettingsSliderRow(
              label: 'Side margin',
              value: prefs.marginHorizontal,
              min: 0,
              max: 64,
              divisions: 32,
              format: (v) => '${v.round()} px',
              onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(marginHorizontal: v),
                documentPath: path,
              ),
            ),
            SettingsSliderRow(
              label: 'Top margin',
              value: prefs.marginTop,
              min: 0,
              max: 64,
              divisions: 32,
              format: (v) => '${v.round()} px',
              onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(marginTop: v),
                documentPath: path,
              ),
            ),
            SettingsSliderRow(
              label: 'Bottom margin',
              value: prefs.marginBottom,
              min: 0,
              max: 64,
              divisions: 32,
              format: (v) => '${v.round()} px',
              onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(marginBottom: v),
                documentPath: path,
              ),
            ),
          ],
        );
      },
    );
  }
}
