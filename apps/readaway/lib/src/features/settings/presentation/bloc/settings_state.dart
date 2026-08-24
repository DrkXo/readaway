part of 'settings_bloc.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ReaderPreferences globalReaderPrefs,
    required Map<String, ReaderPreferences> documentReaderPrefs,
    String? activeDocumentPath,
    @Default(Settings()) Settings appSettings,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
