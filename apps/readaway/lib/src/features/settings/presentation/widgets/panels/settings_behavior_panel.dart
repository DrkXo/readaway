import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/models/reader_preferences.dart';

import '../../bloc/settings/settings_bloc.dart';
import '../settings_bloc_x.dart';
import '../widgets.dart';

class SettingsBehaviorPanel extends StatelessWidget {
  const SettingsBehaviorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs != curr.globalReaderPrefs ||
          prev.appSettings != curr.appSettings,
      builder: (context, state) {
        final settings = state.appSettings;

        void resetPageTurning() {
          context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(
              scrollDirection: ReaderScrollDirection.horizontal,
              pageTransition: ReaderPageTransition.slide,
              pageSnap: true,
            ),
          );
        }

        void resetNavigation() {
          context.read<SettingsBloc>().add(
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
          context.read<SettingsBloc>().add(
            SettingsEvent.updateAppSettings(
              settings.copyWith(screenWakeLock: false),
            ),
          );
          context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showStatusBar: true),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SettingsSection(
              title: 'Page turning',
              onReset: resetPageTurning,
              rows: const [
                _ScrollDirectionRow(),
                _PageTransitionRow(),
                _PageSnapRow(),
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
      },
    );
  }
}

class _ScrollDirectionRow extends StatelessWidget {
  const _ScrollDirectionRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.scrollDirection !=
          curr.globalReaderPrefs.scrollDirection,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
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
          onChanged: (direction) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(scrollDirection: direction),
          ),
        );
      },
    );
  }
}

class _PageTransitionRow extends StatelessWidget {
  const _PageTransitionRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.pageTransition !=
          curr.globalReaderPrefs.pageTransition,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        return SettingsSelectRow<ReaderPageTransition>(
          label: 'Page transition',
          value: prefs.pageTransition,
          entries: const [
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
            SettingsSelectEntry(
              value: ReaderPageTransition.curl,
              label: 'Curl / Flip',
            ),
          ],
          onChanged: (transition) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(pageTransition: transition),
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
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.pageSnap !=
          curr.globalReaderPrefs.pageSnap,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        return SettingsSwitchRow(
          label: 'Snap to page',
          description: 'Settle on page boundaries while scrolling',
          value: prefs.pageSnap,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(pageSnap: v),
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
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.globalReaderPrefs.showStatusBar !=
          curr.globalReaderPrefs.showStatusBar,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        return SettingsSwitchRow(
          label: 'Show status bar',
          description: 'Progress indicator at the top of the reader',
          value: prefs.showStatusBar,
          onChanged: (v) => context.read<SettingsBloc>().updateReaderPrefs(
            (p) => p.copyWith(showStatusBar: v),
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
