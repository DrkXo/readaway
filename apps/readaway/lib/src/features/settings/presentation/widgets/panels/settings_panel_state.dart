import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/reader_preferences.dart';
import '../../bloc/settings/settings_bloc.dart';

/// Mixin for settings panel states that need global/per-book scope handling.
///
/// Encapsulates the duplicated `_isGlobalMode` field and `resetSection` logic
/// used across the font and layout panels.
mixin SettingsPanelState<T extends StatefulWidget> on State<T> {
  bool isGlobalMode = true;

  void resetSection(
    ReaderPreferences Function(ReaderPreferences) update,
  ) {
    final bloc = context.read<SettingsBloc>();
    final current = bloc.state;
    final path = current.activeDocumentPath;
    if (!isGlobalMode && path != null) {
      bloc.add(
        SettingsEvent.setDocumentReaderPref(
          path: path,
          prefs: update(current.resolvedReaderPrefs(path)),
        ),
      );
    } else {
      bloc.add(
        SettingsEvent.setGlobalReaderPref(update(current.globalReaderPrefs)),
      );
    }
  }
}
