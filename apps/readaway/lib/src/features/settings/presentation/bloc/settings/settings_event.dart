part of 'settings_bloc.dart';

@freezed
abstract class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.setGlobalReaderPref(ReaderPreferences prefs) =
      _SetGlobalReaderPref;
  const factory SettingsEvent.setDocumentReaderPref({
    required String path,
    required ReaderPreferences prefs,
  }) = _SetDocumentReaderPref;
  const factory SettingsEvent.resetDocumentReaderPref(String path) =
      _ResetDocumentReaderPref;
  const factory SettingsEvent.resetAllReaderPrefs() = _ResetAllReaderPrefs;
  const factory SettingsEvent.importReaderPrefs(
    Map<String, ReaderPreferences> all,
  ) = _ImportReaderPrefs;
  const factory SettingsEvent.updateAppSettings(Settings settings) =
      _UpdateAppSettings;
}
