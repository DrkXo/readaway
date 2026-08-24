import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/reader_preferences.dart';
import '../bloc/settings_bloc.dart';

/// Segmented control for choosing whether reader settings apply to all books
/// (global) or only the currently open book (per-book).
class ScopeToggle extends StatelessWidget {
  const ScopeToggle({
    super.key,
    required this.isGlobalMode,
    required this.onChanged,
  });

  final bool isGlobalMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('All books')),
        ButtonSegment(value: false, label: Text('This book')),
      ],
      selected: {isGlobalMode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Dispatches a reader-preference update to the [SettingsBloc], honoring the
/// current scope: global writes go to `setGlobalReaderPref`, per-book writes
/// go to `setDocumentReaderPref` for [activePath].
///
/// Per-book writes store a full snapshot of the resolved preferences so the
/// book keeps its own settings even if global settings change later.
void updateReaderPrefs(
  BuildContext context,
  SettingsState state,
  String? activePath,
  bool isGlobalMode,
  ReaderPreferences Function(ReaderPreferences) update,
) {
  final bloc = context.read<SettingsBloc>();
  if (!isGlobalMode && activePath != null) {
    bloc.add(
      SettingsEvent.setDocumentReaderPref(
        path: activePath,
        prefs: update(state.resolvedReaderPrefs(activePath)),
      ),
    );
  } else {
    bloc.add(
      SettingsEvent.setGlobalReaderPref(update(state.globalReaderPrefs)),
    );
  }
}
