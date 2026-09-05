import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/settings/settings_bloc.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';

class SettingsLayoutPanel extends StatelessWidget {
  const SettingsLayoutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SettingsSection(
          title: 'Page margins',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              marginHorizontal: 16,
              marginTop: 16,
              marginBottom: 16,
            ),
          ),
          rows: const [
            _MarginPresetRow(),
            _MarginSliderRow(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Paragraph',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              paragraphMargin: 0.5,
              textIndent: 0,
              fullJustification: true,
            ),
          ),
          rows: const [
            _ParagraphSpacingRow(),
            _TextIndentRow(),
            _FullJustificationRow(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Text',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              lineHeight: 1.5,
              letterSpacing: 0,
              wordSpacing: 0,
            ),
          ),
          rows: const [
            _LineHeightRow(),
            _LetterSpacingRow(),
            _WordSpacingRow(),
          ],
        ),
      ],
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
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.marginHorizontal !=
          curr.globalReaderPrefs.marginHorizontal,
      builder: (context, state) {
        final current = state.globalReaderPrefs.marginHorizontal;
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
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.marginHorizontal !=
              curr.globalReaderPrefs.marginHorizontal ||
          prev.globalReaderPrefs.marginTop !=
              curr.globalReaderPrefs.marginTop ||
          prev.globalReaderPrefs.marginBottom !=
              curr.globalReaderPrefs.marginBottom,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        return SettingsSliderRow(
          label: 'Page margin',
          value: prefs.marginHorizontal,
          min: 0,
          max: 64,
          divisions: 16,
          format: (v) => '${v.round()} px',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              marginHorizontal: v,
              marginTop: v,
              marginBottom: v,
            ),
          ),
        );
      },
    );
  }
}

class _ParagraphSpacingRow extends StatelessWidget {
  const _ParagraphSpacingRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.paragraphMargin !=
          curr.globalReaderPrefs.paragraphMargin,
      builder: (context, state) {
        final margin = state.globalReaderPrefs.paragraphMargin;
        return SettingsSliderRow(
          label: 'Paragraph spacing',
          value: margin,
          min: 0,
          max: 2,
          divisions: 20,
          format: (v) => v.toStringAsFixed(1),
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(paragraphMargin: v),
          ),
        );
      },
    );
  }
}

class _TextIndentRow extends StatelessWidget {
  const _TextIndentRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.textIndent !=
          curr.globalReaderPrefs.textIndent,
      builder: (context, state) {
        final indent = state.globalReaderPrefs.textIndent;
        return SettingsSliderRow(
          label: 'Text indent',
          value: indent,
          min: 0,
          max: 4,
          divisions: 8,
          format: (v) => '${v.toStringAsFixed(1)} em',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(textIndent: v),
          ),
        );
      },
    );
  }
}

class _FullJustificationRow extends StatelessWidget {
  const _FullJustificationRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.fullJustification !=
          curr.globalReaderPrefs.fullJustification,
      builder: (context, state) {
        final enabled = state.globalReaderPrefs.fullJustification;
        return SettingsSwitchRow(
          label: 'Full justification',
          value: enabled,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(fullJustification: v),
          ),
        );
      },
    );
  }
}

class _LineHeightRow extends StatelessWidget {
  const _LineHeightRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.lineHeight !=
          curr.globalReaderPrefs.lineHeight,
      builder: (context, state) {
        final lineHeight = state.globalReaderPrefs.lineHeight;
        return SettingsSliderRow(
          label: 'Line height',
          value: lineHeight,
          min: 0.8,
          max: 3,
          divisions: 44,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(lineHeight: v),
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
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.letterSpacing !=
          curr.globalReaderPrefs.letterSpacing,
      builder: (context, state) {
        final spacing = state.globalReaderPrefs.letterSpacing;
        return SettingsSliderRow(
          label: 'Letter spacing',
          value: spacing,
          min: -0.1,
          max: 0.3,
          divisions: 40,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(letterSpacing: v),
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
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.wordSpacing !=
          curr.globalReaderPrefs.wordSpacing,
      builder: (context, state) {
        final spacing = state.globalReaderPrefs.wordSpacing;
        return SettingsSliderRow(
          label: 'Word spacing',
          value: spacing,
          min: 0,
          max: 10,
          divisions: 10,
          format: (v) => '${v.round()} px',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(wordSpacing: v),
          ),
        );
      },
    );
  }
}
