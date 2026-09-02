import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/reader_preferences.dart';
import '../../bloc/settings/settings_bloc.dart';

/// A [BlocBuilder] wrapper that rebuilds only when the resolved reader
/// preferences for [activePath] change.
///
/// Encapsulates the common `buildWhen: (prev, curr) =>
/// prev.resolvedReaderPrefs(activePath) !=
/// curr.resolvedReaderPrefs(activePath)` pattern used across the settings
/// row widgets.
class ReaderPrefsBuilder extends StatelessWidget {
  const ReaderPrefsBuilder({
    super.key,
    required this.activePath,
    required this.builder,
  });

  final String? activePath;
  final Widget Function(BuildContext context, ReaderPreferences prefs) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.resolvedReaderPrefs(activePath) !=
          curr.resolvedReaderPrefs(activePath),
      builder: (context, state) =>
          builder(context, state.resolvedReaderPrefs(activePath)),
    );
  }
}
