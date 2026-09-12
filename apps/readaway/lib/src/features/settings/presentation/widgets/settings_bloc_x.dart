import '../../domain/entity/reader_preferences.dart';
import '../bloc/settings/settings_bloc.dart';

/// Extension on [SettingsBloc] for reader-preference updates.
extension SettingsBlocX on SettingsBloc {
  /// Dispatches a reader-preference update.
  ///
  /// When [documentPath] is provided the update targets that document's
  /// overrides (starting from its current effective prefs); otherwise it
  /// targets the global preferences.
  void updateReaderPrefs(
    ReaderPreferences Function(ReaderPreferences) update, {
    String? documentPath,
  }) {
    if (documentPath != null) {
      updateDocumentReaderPrefs(documentPath, update);
    } else {
      add(SettingsEvent.setGlobalReaderPref(update(state.globalReaderPrefs)));
    }
  }

  /// Dispatches a reader-preference update to a document's overrides.
  ///
  /// The update is applied on top of the document's current overrides (or the
  /// global prefs when the document has no override yet), so per-book edits
  /// always start from the effective values the user sees.
  void updateDocumentReaderPrefs(
    String path,
    ReaderPreferences Function(ReaderPreferences) update,
  ) {
    final current = state.documentReaderPrefs[path] ?? state.globalReaderPrefs;
    add(SettingsEvent.setDocumentReaderPref(path, update(current)));
  }

  /// Clears a document's overrides so it falls back to global preferences.
  void clearDocumentReaderPrefs(String path) {
    add(SettingsEvent.clearDocumentPrefs(path));
  }
}
