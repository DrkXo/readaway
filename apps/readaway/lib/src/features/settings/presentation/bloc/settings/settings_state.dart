part of 'settings_bloc.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ReaderPreferences globalReaderPrefs,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default({})
    Map<String, ReaderPreferences> documentReaderPrefs,
    @Default(Settings()) Settings appSettings,
    @JsonKey(includeFromJson: false, includeToJson: false) Failure? failure,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String>{})
    Set<String> loadedDocumentPaths,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}

extension SettingsStateX on SettingsState {
  ReaderPreferences get readerPrefs => globalReaderPrefs;

  /// The effective reader preferences for [documentPath]: the document's
  /// per-book override when one exists, otherwise the global preferences.
  /// Pass null to always get the global preferences.
  ReaderPreferences effectiveReaderPrefs(String? documentPath) {
    if (documentPath != null) {
      return documentReaderPrefs[documentPath] ?? globalReaderPrefs;
    }
    return globalReaderPrefs;
  }
}
