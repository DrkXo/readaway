part of 'tts_library_bloc.dart';

@freezed
abstract class TtsLibraryEvent with _$TtsLibraryEvent {
  const factory TtsLibraryEvent.refreshCatalog({@Default(false) bool force}) =
      _RefreshCatalog;
  const factory TtsLibraryEvent.checkForUpdates() = _CheckForUpdates;
  const factory TtsLibraryEvent.startDownload(SherpaTtsModelInfo model) =
      _StartDownload;
  const factory TtsLibraryEvent.pauseDownload(String modelId) = _PauseDownload;
  const factory TtsLibraryEvent.resumeDownload(String modelId) =
      _ResumeDownload;
  const factory TtsLibraryEvent.resumeInterrupted() = _ResumeInterrupted;
  const factory TtsLibraryEvent.cancelDownload(String modelId) =
      _CancelDownload;
  const factory TtsLibraryEvent.deleteModel(SherpaTtsModelInfo model) =
      _DeleteModel;
  const factory TtsLibraryEvent.activate(String modelId) = _Activate;
  const factory TtsLibraryEvent.preview(String modelId) = _Preview;
  const factory TtsLibraryEvent.importCustomModel({
    required CustomModelInspectionResult inspection,
    required String displayName,
    required String languageCode,
    required String languageLabel,
    SherpaTtsModelType? typeOverride,
    @Default(0) int speakerCount,
    @Default(22050) int sampleRate,
  }) = _ImportCustomModel;

  // Internal stream events — mirror the live catalog, installed voices, and
  // download-manager snapshots into state.
  const factory TtsLibraryEvent.catalogUpdated(
    List<SherpaTtsModelInfo> models,
  ) = _CatalogUpdated;
  const factory TtsLibraryEvent.installedModelsUpdated(
    List<SherpaTtsModelInfo> models,
  ) = _InstalledModelsUpdated;
  const factory TtsLibraryEvent.downloadsUpdated(
    Map<String, TtsDownloadTask> tasks,
  ) = _DownloadsUpdated;
}
