import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../domain/entity/reader_preferences.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../reader_prefs_scope.dart';
import '../../settings_bloc_x.dart';
import '../../widgets.dart';

/// Paragraph spacing and text alignment settings for the reader.
class SettingsLayoutParagraphSection extends StatelessWidget {
  const SettingsLayoutParagraphSection({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return ScopedSettingsSection(
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
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Paragraph spacing',
          value: prefs.paragraphMargin,
          min: 0,
          max: 2,
          divisions: 20,
          enabled: prefs.overrideLayout,
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
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSliderRow(
          label: 'Text indent',
          value: prefs.textIndent,
          min: 0,
          max: 4,
          divisions: 8,
          enabled: prefs.overrideLayout,
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
        final prefs = state.effectiveReaderPrefs(path);
        final enabled = prefs.appliesTextAlignment;
        final current = prefs.textAlign;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Text alignment',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: enabled
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
              SegmentedButton<ReaderTextAlign>(
                segments: const [
                  ButtonSegment(
                    value: ReaderTextAlign.left,
                    icon: Icon(LucideIcons.alignLeft),
                    tooltip: 'Left',
                  ),
                  ButtonSegment(
                    value: ReaderTextAlign.center,
                    icon: Icon(LucideIcons.alignCenter),
                    tooltip: 'Center',
                  ),
                  ButtonSegment(
                    value: ReaderTextAlign.right,
                    icon: Icon(LucideIcons.alignRight),
                    tooltip: 'Right',
                  ),
                  ButtonSegment(
                    value: ReaderTextAlign.justify,
                    icon: Icon(LucideIcons.alignJustify),
                    tooltip: 'Justify',
                  ),
                ],
                selected: {current},
                onSelectionChanged: enabled
                    ? (s) {
                        if (s.isEmpty) return;
                        context.read<SettingsBloc>().updateReaderPrefs(
                          (p) => p.copyWith(textAlign: s.first),
                          documentPath: path,
                        );
                      }
                    : null,
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
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSwitchRow(
          label: 'Keep book text alignment',
          description:
              'Preserve the book\'s own alignment (e.g. centered poetry) '
              'instead of overriding it.',
          value: prefs.keepTextAlignment,
          enabled: prefs.overrideLayout,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(keepTextAlignment: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}
