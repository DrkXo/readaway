import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../domain/entity/reader_preferences.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../reader_prefs_scope.dart';
import '../../settings_bloc_x.dart';
import '../../widgets.dart';

/// Header and footer display settings for the reader.
class SettingsLayoutHeaderFooterSection extends StatelessWidget {
  const SettingsLayoutHeaderFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return ScopedSettingsSection(
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
        final enabled = prefs.showHeader;
        final current = prefs.headerAlignment;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Header position',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: enabled
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
              SegmentedButton<ReaderHeaderAlignment>(
                segments: const [
                  ButtonSegment(
                    value: ReaderHeaderAlignment.left,
                    icon: Icon(LucideIcons.alignLeft),
                    tooltip: 'Left',
                  ),
                  ButtonSegment(
                    value: ReaderHeaderAlignment.center,
                    icon: Icon(LucideIcons.alignCenter),
                    tooltip: 'Center',
                  ),
                  ButtonSegment(
                    value: ReaderHeaderAlignment.right,
                    icon: Icon(LucideIcons.alignRight),
                    tooltip: 'Right',
                  ),
                ],
                selected: {current},
                onSelectionChanged: enabled
                    ? (s) {
                        if (s.isEmpty) return;
                        context.read<SettingsBloc>().updateReaderPrefs(
                          (p) => p.copyWith(headerAlignment: s.first),
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
        final enabled = prefs.showFooter;
        final current = prefs.footerProgressStyle;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Progress display',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: enabled
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
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
                onSelectionChanged: enabled
                    ? (s) {
                        if (s.isEmpty) return;
                        context.read<SettingsBloc>().updateReaderPrefs(
                          (p) => p.copyWith(footerProgressStyle: s.first),
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
        return SettingsSwitchRow(
          label: 'Remaining pages in chapter',
          value: prefs.showRemainingPages,
          enabled: prefs.showFooter,
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
        return SettingsSwitchRow(
          label: 'Clock',
          description: 'Show current time in the footer.',
          value: prefs.showCurrentTime,
          enabled: prefs.showFooter,
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
        return SettingsSwitchRow(
          label: 'Battery indicator',
          description: 'Show battery icon in the footer.',
          value: prefs.showBatteryStatus,
          enabled: prefs.showFooter,
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
        return SettingsSwitchRow(
          label: 'Progress bar line',
          description: 'Show a slim progress track along the footer bottom.',
          value: prefs.showFooterProgressBar,
          enabled: prefs.showFooter,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showFooterProgressBar: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}
