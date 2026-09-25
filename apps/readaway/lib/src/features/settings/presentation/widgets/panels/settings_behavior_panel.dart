import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entity/reader_preferences.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../reader_prefs_scope.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';

class SettingsBehaviorPanel extends StatelessWidget {
  const SettingsBehaviorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    final bloc = context.read<SettingsBloc>();

    void resetPageTurning() {
      bloc.updateReaderPrefs(
        (p) => p.copyWith(
          scrollDirection: ReaderScrollDirection.horizontal,
          pageTransition: ReaderPageTransition.slide,
          pageSnap: true,
          nonReflowableScrollDirection: ReaderScrollDirection.vertical,
          nonReflowablePageTransition: ReaderPageTransition.slide,
          nonReflowablePageSnap: true,
        ),
        documentPath: path,
      );
    }

    void resetNavigation() {
      final settings = bloc.state.appSettings;
      bloc.add(
        SettingsEvent.updateAppSettings(
          settings.copyWith(
            globalViewSettings: settings.globalViewSettings.copyWith(
              volumeKeysToFlip: false,
              pageTurnStyle: 'slide',
            ),
          ),
        ),
      );
    }

    void resetSystem() {
      final settings = bloc.state.appSettings;
      bloc.add(
        SettingsEvent.updateAppSettings(
          settings.copyWith(screenWakeLock: false),
        ),
      );
      bloc.updateReaderPrefs(
        (p) => p.copyWith(showStatusBar: true),
        documentPath: path,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SettingsSection(
          title: 'Reflowable books (EPUB, TXT)',
          onReset: resetPageTurning,
          rows: const [
            _ScrollDirectionRow(),
            _PageTransitionRow(),
            _PageSnapRow(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Fixed layout & documents (PDF, CBZ, CBR)',
          onReset: resetPageTurning,
          rows: const [
            _NonReflowableScrollDirectionRow(),
            _NonReflowablePageTransitionRow(),
            _NonReflowablePageSnapRow(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Navigation',
          onReset: resetNavigation,
          rows: const [
            _VolumeKeysToFlipRow(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'System',
          onReset: resetSystem,
          rows: const [
            _KeepScreenOnRow(),
            _ShowStatusBarRow(),
          ],
        ),
      ],
    );
  }
}

class _ScrollDirectionRow extends StatelessWidget {
  const _ScrollDirectionRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSelectRow<ReaderScrollDirection>(
          label: 'Scroll direction',
          value: prefs.scrollDirection,
          entries: const [
            SettingsSelectEntry(
              value: ReaderScrollDirection.horizontal,
              label: 'Horizontal',
            ),
            SettingsSelectEntry(
              value: ReaderScrollDirection.vertical,
              label: 'Vertical',
            ),
          ],
          onChanged: (direction) =>
              context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(scrollDirection: direction),
                documentPath: path,
              ),
        );
      },
    );
  }
}

class _NonReflowableScrollDirectionRow extends StatelessWidget {
  const _NonReflowableScrollDirectionRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSelectRow<ReaderScrollDirection>(
          label: 'Scroll direction',
          value: prefs.nonReflowableScrollDirection,
          entries: const [
            SettingsSelectEntry(
              value: ReaderScrollDirection.vertical,
              label: 'Vertical',
            ),
            SettingsSelectEntry(
              value: ReaderScrollDirection.horizontal,
              label: 'Horizontal',
            ),
          ],
          onChanged: (direction) =>
              context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(nonReflowableScrollDirection: direction),
                documentPath: path,
              ),
        );
      },
    );
  }
}

class _PageTransitionRow extends StatelessWidget {
  const _PageTransitionRow();

  static const _allEntries = [
    SettingsSelectEntry(
      value: ReaderPageTransition.none,
      label: 'None',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.fade,
      label: 'Fade',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.slide,
      label: 'Slide',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.sharedAxis,
      label: 'Shared axis',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.cover,
      label: 'Cover',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        // Only show transitions supported by the current scroll direction.
        final entries = _allEntries
            .where((e) => e.value.isSupportedFor(prefs.scrollDirection))
            .toList();
        return SettingsSelectRow<ReaderPageTransition>(
          label: 'Page transition',
          value: prefs.pageTransition,
          entries: entries,
          onChanged: (transition) =>
              context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(pageTransition: transition),
                documentPath: path,
              ),
        );
      },
    );
  }
}

class _NonReflowablePageTransitionRow extends StatelessWidget {
  const _NonReflowablePageTransitionRow();

  static const _allEntries = [
    SettingsSelectEntry(
      value: ReaderPageTransition.none,
      label: 'None',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.fade,
      label: 'Fade',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.slide,
      label: 'Slide',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.sharedAxis,
      label: 'Shared axis',
    ),
    SettingsSelectEntry(
      value: ReaderPageTransition.cover,
      label: 'Cover',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        final entries = _allEntries
            .where(
              (e) => e.value.isSupportedFor(prefs.nonReflowableScrollDirection),
            )
            .toList();
        return SettingsSelectRow<ReaderPageTransition>(
          label: 'Page transition',
          value: prefs.nonReflowablePageTransition,
          entries: entries,
          onChanged: (transition) =>
              context.read<SettingsBloc>().updateReaderPrefs(
                (p) => p.copyWith(nonReflowablePageTransition: transition),
                documentPath: path,
              ),
        );
      },
    );
  }
}

class _PageSnapRow extends StatelessWidget {
  const _PageSnapRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSwitchRow(
          label: 'Snap to page',
          description: 'Settle on page boundaries while scrolling',
          value: prefs.pageSnap,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(pageSnap: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _NonReflowablePageSnapRow extends StatelessWidget {
  const _NonReflowablePageSnapRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSwitchRow(
          label: 'Snap to page',
          description: 'Settle on page boundaries while scrolling',
          value: prefs.nonReflowablePageSnap,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(nonReflowablePageSnap: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _KeepScreenOnRow extends StatelessWidget {
  const _KeepScreenOnRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.screenWakeLock != curr.appSettings.screenWakeLock,
      builder: (context, state) {
        final enabled = state.appSettings.screenWakeLock;
        return SettingsSwitchRow(
          label: 'Keep screen on',
          description: 'Prevent the screen from sleeping while reading',
          value: enabled,
          onChanged: (v) {
            final settings = state.appSettings;
            context.read<SettingsBloc>().add(
              SettingsEvent.updateAppSettings(
                settings.copyWith(screenWakeLock: v),
              ),
            );
          },
        );
      },
    );
  }
}

class _ShowStatusBarRow extends StatelessWidget {
  const _ShowStatusBarRow();

  @override
  Widget build(BuildContext context) {
    final path = context.readerPrefsDocumentPath();
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.effectiveReaderPrefs(path) != curr.effectiveReaderPrefs(path),
      builder: (context, state) {
        final prefs = state.effectiveReaderPrefs(path);
        return SettingsSwitchRow(
          label: 'Show status bar',
          description: 'Progress indicator at the top of the reader',
          value: prefs.showStatusBar,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showStatusBar: v),
            documentPath: path,
          ),
        );
      },
    );
  }
}

class _VolumeKeysToFlipRow extends StatelessWidget {
  const _VolumeKeysToFlipRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.volumeKeysToFlip !=
          curr.appSettings.globalViewSettings.volumeKeysToFlip,
      builder: (context, state) {
        final enabled = state.appSettings.globalViewSettings.volumeKeysToFlip;
        return SettingsSwitchRow(
          label: 'Volume keys to flip pages',
          value: enabled,
          onChanged: (v) {
            final settings = state.appSettings;
            context.read<SettingsBloc>().add(
              SettingsEvent.updateAppSettings(
                settings.copyWith(
                  globalViewSettings: settings.globalViewSettings.copyWith(
                    volumeKeysToFlip: v,
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
