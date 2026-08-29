import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/reader_preferences.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../widgets.dart';

class BehaviorPanel extends StatelessWidget {
  const BehaviorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        final settings = state.appSettings;

        void resetPageTurning() {
          context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              prefs.copyWith(
                scrollDirection: ReaderScrollDirection.horizontal,
                pageTransition: ReaderPageTransition.slide,
                pageSnap: true,
              ),
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

        void resetAutoScroll() {
          context.read<SettingsBloc>().add(
            SettingsEvent.updateAppSettings(
              settings.copyWith(
                globalViewSettings: settings.globalViewSettings.copyWith(
                  autoScrollRunning: false,
                  autoScrollSpeed: 1,
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
          context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              prefs.copyWith(showStatusBar: true),
            ),
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
                _PageTurnStyleRow(),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Auto scroll',
              onReset: resetAutoScroll,
              rows: const [_AutoScrollRow()],
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
          onChanged: (direction) => context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              prefs.copyWith(scrollDirection: direction),
            ),
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
          ],
          onChanged: (transition) => context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              prefs.copyWith(pageTransition: transition),
            ),
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
          prev.globalReaderPrefs.pageSnap != curr.globalReaderPrefs.pageSnap,
      builder: (context, state) {
        final prefs = state.globalReaderPrefs;
        return SettingsSwitchRow(
          label: 'Snap to page',
          description: 'Settle on page boundaries while scrolling',
          value: prefs.pageSnap,
          onChanged: (v) => context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(prefs.copyWith(pageSnap: v)),
          ),
        );
      },
    );
  }
}

class _AutoScrollRow extends StatelessWidget {
  const _AutoScrollRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.autoScrollRunning !=
              curr.appSettings.globalViewSettings.autoScrollRunning ||
          prev.appSettings.globalViewSettings.autoScrollSpeed !=
              curr.appSettings.globalViewSettings.autoScrollSpeed,
      builder: (context, state) {
        final view = state.appSettings.globalViewSettings;
        final enabled = view.autoScrollRunning;
        final speed = view.autoScrollSpeed;

        void update({bool? running, int? speedValue}) {
          final settings = state.appSettings;
          context.read<SettingsBloc>().add(
            SettingsEvent.updateAppSettings(
              settings.copyWith(
                globalViewSettings: settings.globalViewSettings.copyWith(
                  autoScrollRunning: running ?? view.autoScrollRunning,
                  autoScrollSpeed: speedValue ?? view.autoScrollSpeed,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            SettingsSwitchRow(
              label: 'Enable auto scroll',
              description: 'Automatically scroll through the page',
              value: enabled,
              onChanged: (v) => update(running: v),
            ),
            SettingsSliderRow(
              label: 'Speed',
              value: speed.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              enabled: enabled,
              format: (v) => '${v.round()}×',
              onChanged: (v) => update(speedValue: v.round()),
            ),
          ],
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
          onChanged: (v) => context.read<SettingsBloc>().add(
            SettingsEvent.setGlobalReaderPref(
              prefs.copyWith(showStatusBar: v),
            ),
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

class _PageTurnStyleRow extends StatelessWidget {
  const _PageTurnStyleRow();

  static const _entries = [
    SettingsSelectEntry(value: 'slide', label: 'Slide'),
    SettingsSelectEntry(value: 'fade', label: 'Fade'),
    SettingsSelectEntry(value: 'none', label: 'None'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.appSettings.globalViewSettings.pageTurnStyle !=
          curr.appSettings.globalViewSettings.pageTurnStyle,
      builder: (context, state) {
        final value = state.appSettings.globalViewSettings.pageTurnStyle;
        return SettingsSelectRow<String>(
          label: 'Page turn animation',
          value: value,
          entries: _entries,
          onChanged: (v) {
            final settings = state.appSettings;
            context.read<SettingsBloc>().add(
              SettingsEvent.updateAppSettings(
                settings.copyWith(
                  globalViewSettings: settings.globalViewSettings.copyWith(
                    pageTurnStyle: v,
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
