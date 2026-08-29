import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/reader_preferences.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../widgets.dart';

class LayoutPanel extends StatefulWidget {
  const LayoutPanel({super.key, this.showScopeToggle = false});

  final bool showScopeToggle;

  @override
  State<LayoutPanel> createState() => _LayoutPanelState();
}

class _LayoutPanelState extends State<LayoutPanel> {
  bool _isGlobalMode = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.activeDocumentPath != curr.activeDocumentPath,
      builder: (context, state) {
        final activePath = state.activeDocumentPath;
        final showScope = widget.showScopeToggle && activePath != null;
        final scope = showScope
            ? (_isGlobalMode ? SettingsScope.global : SettingsScope.perBook)
            : null;

        void resetSection(
          ReaderPreferences Function(ReaderPreferences) update,
        ) {
          final bloc = context.read<SettingsBloc>();
          final current = bloc.state;
          final path = current.activeDocumentPath;
          if (!_isGlobalMode && path != null) {
            bloc.add(
              SettingsEvent.setDocumentReaderPref(
                path: path,
                prefs: update(current.resolvedReaderPrefs(path)),
              ),
            );
          } else {
            bloc.add(
              SettingsEvent.setGlobalReaderPref(
                update(current.globalReaderPrefs),
              ),
            );
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (showScope) ...[
              ScopeToggle(
                isGlobalMode: _isGlobalMode,
                onChanged: (v) => setState(() => _isGlobalMode = v),
              ),
              const SizedBox(height: 16),
            ],
            SettingsSection(
              title: 'Page margins',
              scope: scope,
              onReset: () => resetSection(
                (p) => p.copyWith(
                  marginHorizontal: 16,
                  marginTop: 16,
                  marginBottom: 16,
                ),
              ),
              rows: [
                _MarginPresetRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
                _MarginSliderRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Paragraph',
              scope: scope,
              onReset: () => resetSection(
                (p) => p.copyWith(
                  paragraphMargin: 0.5,
                  textIndent: 0,
                  fullJustification: true,
                ),
              ),
              rows: [
                _ParagraphSpacingRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
                _TextIndentRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
                _FullJustificationRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Text',
              scope: scope,
              onReset: () => resetSection(
                (p) => p.copyWith(
                  lineHeight: 1.5,
                  letterSpacing: 0,
                  wordSpacing: 0,
                ),
              ),
              rows: [
                _LineHeightRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
                _LetterSpacingRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
                _WordSpacingRow(
                  isGlobalMode: _isGlobalMode,
                  activePath: activePath,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MarginPresetRow extends StatelessWidget {
  const _MarginPresetRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  static const _presets = [
    (value: 8.0, label: 'Compact'),
    (value: 16.0, label: 'Normal'),
    (value: 24.0, label: 'Wide'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).marginHorizontal !=
          curr.resolvedReaderPrefs(activePath).marginHorizontal,
      builder: (context, state) {
        final current = state.resolvedReaderPrefs(activePath).marginHorizontal;
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
              updateReaderPrefs(
                context,
                state,
                activePath,
                isGlobalMode,
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
  const _MarginSliderRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).marginHorizontal !=
              curr.resolvedReaderPrefs(activePath).marginHorizontal ||
          prev.resolvedReaderPrefs(activePath).marginTop !=
              curr.resolvedReaderPrefs(activePath).marginTop ||
          prev.resolvedReaderPrefs(activePath).marginBottom !=
              curr.resolvedReaderPrefs(activePath).marginBottom,
      builder: (context, state) {
        final prefs = state.resolvedReaderPrefs(activePath);
        return SettingsSliderRow(
          label: 'Page margin',
          value: prefs.marginHorizontal,
          min: 0,
          max: 64,
          divisions: 16,
          format: (v) => '${v.round()} px',
          onChanged: (v) => updateReaderPrefs(
            context,
            state,
            activePath,
            isGlobalMode,
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
  const _ParagraphSpacingRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).paragraphMargin !=
          curr.resolvedReaderPrefs(activePath).paragraphMargin,
      builder: (context, state) {
        final margin = state.resolvedReaderPrefs(activePath).paragraphMargin;
        return SettingsSliderRow(
          label: 'Paragraph spacing',
          value: margin,
          min: 0,
          max: 2,
          divisions: 20,
          format: (v) => v.toStringAsFixed(1),
          onChanged: (v) => updateReaderPrefs(
            context,
            state,
            activePath,
            isGlobalMode,
            (p) => p.copyWith(paragraphMargin: v),
          ),
        );
      },
    );
  }
}

class _TextIndentRow extends StatelessWidget {
  const _TextIndentRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).textIndent !=
          curr.resolvedReaderPrefs(activePath).textIndent,
      builder: (context, state) {
        final indent = state.resolvedReaderPrefs(activePath).textIndent;
        return SettingsSliderRow(
          label: 'Text indent',
          value: indent,
          min: 0,
          max: 4,
          divisions: 8,
          format: (v) => '${v.toStringAsFixed(1)} em',
          onChanged: (v) => updateReaderPrefs(
            context,
            state,
            activePath,
            isGlobalMode,
            (p) => p.copyWith(textIndent: v),
          ),
        );
      },
    );
  }
}

class _FullJustificationRow extends StatelessWidget {
  const _FullJustificationRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).fullJustification !=
          curr.resolvedReaderPrefs(activePath).fullJustification,
      builder: (context, state) {
        final enabled = state.resolvedReaderPrefs(activePath).fullJustification;
        return SettingsSwitchRow(
          label: 'Full justification',
          value: enabled,
          onChanged: (v) => updateReaderPrefs(
            context,
            state,
            activePath,
            isGlobalMode,
            (p) => p.copyWith(fullJustification: v),
          ),
        );
      },
    );
  }
}

class _LineHeightRow extends StatelessWidget {
  const _LineHeightRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).lineHeight !=
          curr.resolvedReaderPrefs(activePath).lineHeight,
      builder: (context, state) {
        final lineHeight = state.resolvedReaderPrefs(activePath).lineHeight;
        return SettingsSliderRow(
          label: 'Line height',
          value: lineHeight,
          min: 0.8,
          max: 3,
          divisions: 44,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (v) => updateReaderPrefs(
            context,
            state,
            activePath,
            isGlobalMode,
            (p) => p.copyWith(lineHeight: v),
          ),
        );
      },
    );
  }
}

class _LetterSpacingRow extends StatelessWidget {
  const _LetterSpacingRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).letterSpacing !=
          curr.resolvedReaderPrefs(activePath).letterSpacing,
      builder: (context, state) {
        final spacing = state.resolvedReaderPrefs(activePath).letterSpacing;
        return SettingsSliderRow(
          label: 'Letter spacing',
          value: spacing,
          min: -0.1,
          max: 0.3,
          divisions: 40,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (v) => updateReaderPrefs(
            context,
            state,
            activePath,
            isGlobalMode,
            (p) => p.copyWith(letterSpacing: v),
          ),
        );
      },
    );
  }
}

class _WordSpacingRow extends StatelessWidget {
  const _WordSpacingRow({
    required this.isGlobalMode,
    required this.activePath,
  });

  final bool isGlobalMode;
  final String? activePath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath).wordSpacing !=
          curr.resolvedReaderPrefs(activePath).wordSpacing,
      builder: (context, state) {
        final spacing = state.resolvedReaderPrefs(activePath).wordSpacing;
        return SettingsSliderRow(
          label: 'Word spacing',
          value: spacing,
          min: 0,
          max: 10,
          divisions: 10,
          format: (v) => '${v.round()} px',
          onChanged: (v) => updateReaderPrefs(
            context,
            state,
            activePath,
            isGlobalMode,
            (p) => p.copyWith(wordSpacing: v),
          ),
        );
      },
    );
  }
}
