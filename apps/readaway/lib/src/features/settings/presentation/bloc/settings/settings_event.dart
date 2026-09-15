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

  const factory SettingsEvent.refreshTts() = _RefreshTts;
  const factory SettingsEvent.startTtsDownload(SherpaTtsModelInfo model) =
      _StartTtsDownload;
  const factory SettingsEvent.cancelTtsDownload(String modelId) =
      _CancelTtsDownload;
  const factory SettingsEvent.pauseTtsDownload(String modelId) =
      _PauseTtsDownload;
  const factory SettingsEvent.resumeTtsDownload(String modelId) =
      _ResumeTtsDownload;
  const factory SettingsEvent.deleteTtsModel(SherpaTtsModelInfo model) =
      _DeleteTtsModel;
  const factory SettingsEvent.activateTts(String modelId) = _ActivateTts;
  const factory SettingsEvent.previewTts(String modelId) = _PreviewTts;

  const factory SettingsEvent.ttsDownloadProgress(
    String modelId,
    ModelDownloadStage stage,
    double fraction, {
    double? speedBytesPerSec,
    Duration? timeRemaining,
  }) = _TtsDownloadProgress;
  const factory SettingsEvent.ttsDownloadFailed(String modelId, String error) =
      _TtsDownloadFailed;
}
