import '../../domain/models/reader_preferences.dart';
import '../bloc/settings/settings_bloc.dart';

/// Extension on [SettingsBloc] for reader-preference updates.
extension SettingsBlocX on SettingsBloc {
  /// Dispatches a reader-preference update, honoring the current scope:
  /// global writes go to `setGlobalReaderPref`, per-book writes go to
  /// `setDocumentReaderPref` for [activePath].
  ///
  /// Per-book writes store a full snapshot of the resolved preferences so the
  /// book keeps its own settings even if global settings change later.
  void updateReaderPrefs({
    required SettingsState state,
    String? activePath,
    required bool isGlobalMode,
    required ReaderPreferences Function(ReaderPreferences) update,
  }) {
    if (!isGlobalMode && activePath != null) {
      add(
        SettingsEvent.setDocumentReaderPref(
          path: activePath,
          prefs: update(state.resolvedReaderPrefs(activePath)),
        ),
      );
    } else {
      add(
        SettingsEvent.setGlobalReaderPref(update(state.globalReaderPrefs)),
      );
    }
  }
}
