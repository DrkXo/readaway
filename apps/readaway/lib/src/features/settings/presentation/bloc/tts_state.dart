part of 'tts_bloc.dart';

@freezed
abstract class TtsDownloadStatus with _$TtsDownloadStatus {
  const factory TtsDownloadStatus({
    required ModelDownloadStage stage,
    @Default(0) double fraction,
  }) = _TtsDownloadStatus;
}

@freezed
abstract class TtsState with _$TtsState {
  const factory TtsState({
    @Default([]) List<SherpaTtsModelInfo> availableModels,
    @Default({}) Set<String> downloadedIds,
    @Default({}) Map<String, TtsDownloadStatus> downloads,
    String? activeModelId,
    String? busyModelId,
    @Default(null) String? error,
  }) = _TtsState;
}

extension TtsStateX on TtsState {
  bool isDownloading(String id) => downloads.containsKey(id);
  bool isDownloaded(String id) => downloadedIds.contains(id);
  bool isActive(String id) => activeModelId == id && isDownloaded(id);
  bool isBusy(String id) => busyModelId == id;

  /// Progress of [id]'s download, or null when not downloading.
  TtsDownloadStatus? downloadOf(String id) => downloads[id];
}
