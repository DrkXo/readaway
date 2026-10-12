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
  const factory SettingsEvent.updateAppSettings(
    Settings Function(Settings) update,
  ) = _UpdateAppSettings;

  // Internal stream event — mirrors the live settings store into state so
  // settings written by other owners (library, TTS controller) are reflected
  // and never clobbered by a stale snapshot on the next save.
  const factory SettingsEvent.appSettingsUpdated(Settings settings) =
      _AppSettingsUpdated;
}
