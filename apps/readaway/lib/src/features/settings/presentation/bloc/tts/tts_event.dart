part of 'tts_bloc.dart';

@freezed
abstract class TtsEvent with _$TtsEvent {
  const factory TtsEvent.refresh() = _Refresh;
  const factory TtsEvent.startDownload(SherpaTtsModelInfo model) =
      _StartDownload;
  const factory TtsEvent.cancelDownload(String modelId) = _CancelDownload;
  const factory TtsEvent.deleteModel(SherpaTtsModelInfo model) = _DeleteModel;
  const factory TtsEvent.activate(String modelId) = _Activate;
  const factory TtsEvent.preview(String modelId) = _Preview;

  // Internal events fed by download stream subscriptions.
  const factory TtsEvent.downloadProgress(
    String modelId,
    ModelDownloadStage stage,
    double fraction,
  ) = _DownloadProgress;
  const factory TtsEvent.downloadFailed(String modelId) = _DownloadFailed;
}
