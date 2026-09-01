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

  const factory SettingsEvent.refreshTts() = _RefreshTts;
  const factory SettingsEvent.startTtsDownload(SherpaTtsModelInfo model) =
      _StartTtsDownload;
  const factory SettingsEvent.cancelTtsDownload(String modelId) =
      _CancelTtsDownload;
  const factory SettingsEvent.deleteTtsModel(SherpaTtsModelInfo model) =
      _DeleteTtsModel;
  const factory SettingsEvent.activateTts(String modelId) = _ActivateTts;
  const factory SettingsEvent.previewTts(String modelId) = _PreviewTts;

  const factory SettingsEvent.ttsDownloadProgress(
    String modelId,
    ModelDownloadStage stage,
    double fraction,
  ) = _TtsDownloadProgress;
  const factory SettingsEvent.ttsDownloadFailed(String modelId, String error) =
      _TtsDownloadFailed;
}
