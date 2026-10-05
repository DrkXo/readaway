part of 'tts_library_bloc.dart';

@freezed
abstract class TtsLibraryState with _$TtsLibraryState {
  const factory TtsLibraryState({
    @Default([]) List<SherpaTtsModelInfo> availableModels,
    @Default([]) List<SherpaTtsModelInfo> installedModels,
    @Default({}) Map<String, TtsDownloadTask> downloads,
    String? activeModelId,
    String? busyModelId,
    String? error,
    @Default(false) bool isCheckingUpdates,
    String? updateNotification,
    int? totalCacheSizeBytes,
    int? bookCacheSizeBytes,
    @Default(false) bool isLoadingCacheSize,
    @Default(false) bool isClearingCache,
  }) = _TtsLibraryState;
}

extension TtsLibraryStateX on TtsLibraryState {
  /// Downloaded state is derived from the installed-models list — the Hive
  /// store is the single source of truth and emits both via one watch stream.
  bool isDownloaded(String id) => installedModelById(id) != null;
  bool isActive(String id) => activeModelId == id && isDownloaded(id);
  bool isBusy(String id) => busyModelId == id;

  TtsDownloadTask? taskOf(String id) => downloads[id];

  bool isDownloading(String id) => taskOf(id)?.phase.isActive ?? false;

  SherpaTtsModelInfo? installedModelById(String id) =>
      installedModels.where((m) => m.id == id).firstOrNull;

  bool modelHasUpdate(String id) {
    final installed = installedModelById(id);
    if (installed == null || installed.isCustom) return false;
    final latest = availableModels.where((m) => m.id == id).firstOrNull;
    if (latest == null) return false;
    return installed.hasUpdateAvailable(latest);
  }
}
