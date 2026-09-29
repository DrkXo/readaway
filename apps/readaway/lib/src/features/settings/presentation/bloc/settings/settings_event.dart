part of 'settings_bloc.dart';

@freezed
abstract class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.loadPrefs() = _LoadPrefs;
  const factory SettingsEvent.setGlobalReaderPref(ReaderPreferences prefs) =
      _SetGlobalReaderPref;
  const factory SettingsEvent.loadDocumentPrefs(String path) =
      _LoadDocumentPrefs;
  const factory SettingsEvent.setDocumentReaderPref(
    String path,
    ReaderPreferences prefs,
  ) = _SetDocumentReaderPref;
  const factory SettingsEvent.clearDocumentPrefs(String path) =
      _ClearDocumentPrefs;
  const factory SettingsEvent.resetAllReaderPrefs() = _ResetAllReaderPrefs;
  const factory SettingsEvent.importReaderPrefs(
    Map<String, ReaderPreferences> all,
  ) = _ImportReaderPrefs;
  const factory SettingsEvent.updateAppSettings(Settings settings) =
      _UpdateAppSettings;
}
