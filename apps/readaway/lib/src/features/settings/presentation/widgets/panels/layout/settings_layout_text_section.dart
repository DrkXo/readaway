import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/settings/settings_bloc.dart';
import '../../reader_prefs_scope.dart';
import '../../settings_bloc_x.dart';
import '../../widgets.dart';

/// Text typography spacing settings (line height, letter spacing, word spacing).
class SettingsLayoutTextSection extends StatelessWidget {
  const SettingsLayoutTextSection({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return ScopedSettingsSection(
      title: 'Text',
      onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
        (p) => p.copyWith(
          lineHeight: 1.5,
          letterSpacing: 0,
          wordSpacing: 0,
        ),
        documentPath: path,
      ),
      rows: const [
        _LineHeightRow(),
        _LetterSpacingRow(),
        _WordSpacingRow(),
      ],
    );
  }
}

class _LineHeightRow extends StatelessWidget {
  const _LineHeightRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Line height',
          value: prefs.lineHeight,
          min: 0.8,
          max: 3,
          divisions: 44,
          enabled: prefs.overrideLayout,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(lineHeight: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _LetterSpacingRow extends StatelessWidget {
  const _LetterSpacingRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Letter spacing',
          value: prefs.letterSpacing,
          min: -0.1,
          max: 0.3,
          divisions: 40,
          enabled: prefs.overrideLayout,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(letterSpacing: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _WordSpacingRow extends StatelessWidget {
  const _WordSpacingRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Word spacing',
          value: prefs.wordSpacing,
          min: 0,
          max: 10,
          divisions: 10,
          enabled: prefs.overrideLayout,
          format: (v) => '${v.round()} px',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(wordSpacing: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}
