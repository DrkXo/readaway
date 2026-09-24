import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../settings/domain/entity/reader_preferences.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../reader_prefs_scope.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';

class SettingsLayoutPanel extends StatelessWidget {
  const SettingsLayoutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
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
            documentPath: path,
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
              textAlign: ReaderTextAlign.justify,
              keepTextAlignment: false,
            ),
            documentPath: path,
          ),
          rows: const [
            _ParagraphSpacingRow(),
            _TextIndentRow(),
            _TextAlignRow(),
            _KeepTextAlignmentRow(),
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
            documentPath: path,
          ),
          rows: const [
            _LineHeightRow(),
            _LetterSpacingRow(),
            _WordSpacingRow(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Header & Footer',
          onReset: () => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              showHeader: true,
              headerAlignment: ReaderHeaderAlignment.left,
              headerFontSize: 11.0,
              showFooter: true,
              footerProgressStyle: ReaderProgressStyle.pageNumber,
              showRemainingPages: true,
              showCurrentTime: false,
              showBatteryStatus: false,
              showFooterProgressBar: false,
              footerFontSize: 11.0,
            ),
            documentPath: path,
          ),
          rows: const [
            _ShowHeaderRow(),
            _HeaderAlignmentRow(),
            _ShowFooterRow(),
            _ProgressStyleRow(),
            _RemainingPagesRow(),
            _CurrentTimeRow(),
            _BatteryStatusRow(),
            _ProgressBarRow(),
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
            documentPath: path,
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
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final margin = state.effectiveReaderPrefs(path).paragraphMargin;
        return SettingsSliderRow(
          label: 'Paragraph spacing',
          value: margin,
          min: 0,
          max: 2,
          divisions: 20,
          format: (v) => v.toStringAsFixed(1),
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(paragraphMargin: v),
            documentPath: path,
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
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final indent = state.effectiveReaderPrefs(path).textIndent;
        return SettingsSliderRow(
          label: 'Text indent',
          value: indent,
          min: 0,
          max: 4,
          divisions: 8,
          format: (v) => '${v.toStringAsFixed(1)} em',
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(textIndent: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _TextAlignRow extends StatelessWidget {
  const _TextAlignRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final current = state.effectiveReaderPrefs(path).textAlign;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Text alignment'),
              ),
              SegmentedButton<ReaderTextAlign>(
                segments: const [
                  ButtonSegment(
                    value: ReaderTextAlign.left,
                    icon: Icon(Icons.format_align_left),
                    tooltip: 'Left',
                  ),
                  ButtonSegment(
                    value: ReaderTextAlign.center,
                    icon: Icon(Icons.format_align_center),
                    tooltip: 'Center',
                  ),
                  ButtonSegment(
                    value: ReaderTextAlign.right,
                    icon: Icon(Icons.format_align_right),
                    tooltip: 'Right',
                  ),
                  ButtonSegment(
                    value: ReaderTextAlign.justify,
                    icon: Icon(Icons.format_align_justify),
                    tooltip: 'Justify',
                  ),
                ],
                selected: {current},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  context.read<SettingsBloc>().updateReaderPrefs(
                    (p) => p.copyWith(textAlign: s.first),
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

class _KeepTextAlignmentRow extends StatelessWidget {
  const _KeepTextAlignmentRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final enabled = state.effectiveReaderPrefs(path).keepTextAlignment;
        return SettingsSwitchRow(
          label: 'Keep book text alignment',
          description:
              'Preserve the book\'s own alignment (e.g. centered poetry) '
              'instead of overriding it.',
          value: enabled,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(keepTextAlignment: v),
            documentPath: path,
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
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final lineHeight = state.effectiveReaderPrefs(path).lineHeight;
        return SettingsSliderRow(
          label: 'Line height',
          value: lineHeight,
          min: 0.8,
          max: 3,
          divisions: 44,
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
        final spacing = state.effectiveReaderPrefs(path).letterSpacing;
        return SettingsSliderRow(
          label: 'Letter spacing',
          value: spacing,
          min: -0.1,
          max: 0.3,
          divisions: 40,
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
        final spacing = state.effectiveReaderPrefs(path).wordSpacing;
        return SettingsSliderRow(
          label: 'Word spacing',
          value: spacing,
          min: 0,
          max: 10,
          divisions: 10,
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

class _ShowHeaderRow extends StatelessWidget {
  const _ShowHeaderRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final enabled = state.effectiveReaderPrefs(path).showHeader;
        return SettingsSwitchRow(
          label: 'Show header',
          description: 'Display current chapter title at the top.',
          value: enabled,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showHeader: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _HeaderAlignmentRow extends StatelessWidget {
  const _HeaderAlignmentRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        if (!prefs.showHeader) return const SizedBox.shrink();
        final current = prefs.headerAlignment;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Header position'),
              ),
              SegmentedButton<ReaderHeaderAlignment>(
                segments: const [
                  ButtonSegment(
                    value: ReaderHeaderAlignment.left,
                    icon: Icon(Icons.format_align_left),
                    tooltip: 'Left',
                  ),
                  ButtonSegment(
                    value: ReaderHeaderAlignment.center,
                    icon: Icon(Icons.format_align_center),
                    tooltip: 'Center',
                  ),
                  ButtonSegment(
                    value: ReaderHeaderAlignment.right,
                    icon: Icon(Icons.format_align_right),
                    tooltip: 'Right',
                  ),
                ],
                selected: {current},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  context.read<SettingsBloc>().updateReaderPrefs(
                    (p) => p.copyWith(headerAlignment: s.first),
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

class _ShowFooterRow extends StatelessWidget {
  const _ShowFooterRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final enabled = state.effectiveReaderPrefs(path).showFooter;
        return SettingsSwitchRow(
          label: 'Show footer',
          description: 'Display page count and reading progress at the bottom.',
          value: enabled,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showFooter: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _ProgressStyleRow extends StatelessWidget {
  const _ProgressStyleRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        if (!prefs.showFooter) return const SizedBox.shrink();
        final current = prefs.footerProgressStyle;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Progress display'),
              ),
              SegmentedButton<ReaderProgressStyle>(
                segments: const [
                  ButtonSegment(
                    value: ReaderProgressStyle.pageNumber,
                    label: Text('Page count'),
                  ),
                  ButtonSegment(
                    value: ReaderProgressStyle.percentage,
                    label: Text('Percentage'),
                  ),
                  ButtonSegment(
                    value: ReaderProgressStyle.hidden,
                    label: Text('Hidden'),
                  ),
                ],
                selected: {current},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  context.read<SettingsBloc>().updateReaderPrefs(
                    (p) => p.copyWith(footerProgressStyle: s.first),
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

class _RemainingPagesRow extends StatelessWidget {
  const _RemainingPagesRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        if (!prefs.showFooter) return const SizedBox.shrink();
        return SettingsSwitchRow(
          label: 'Remaining pages in chapter',
          value: prefs.showRemainingPages,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showRemainingPages: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _CurrentTimeRow extends StatelessWidget {
  const _CurrentTimeRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        if (!prefs.showFooter) return const SizedBox.shrink();
        return SettingsSwitchRow(
          label: 'Clock',
          description: 'Show current time in the footer.',
          value: prefs.showCurrentTime,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showCurrentTime: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _BatteryStatusRow extends StatelessWidget {
  const _BatteryStatusRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        if (!prefs.showFooter) return const SizedBox.shrink();
        return SettingsSwitchRow(
          label: 'Battery indicator',
          description: 'Show battery icon in the footer.',
          value: prefs.showBatteryStatus,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showBatteryStatus: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  const _ProgressBarRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        if (!prefs.showFooter) return const SizedBox.shrink();
        return SettingsSwitchRow(
          label: 'Progress bar line',
          description: 'Show a slim progress track along the footer bottom.',
          value: prefs.showFooterProgressBar,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showFooterProgressBar: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}
