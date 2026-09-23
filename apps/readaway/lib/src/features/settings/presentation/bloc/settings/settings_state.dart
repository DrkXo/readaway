part of 'settings_bloc.dart';

@freezed
abstract class SettingsDownloadStatus with _$SettingsDownloadStatus {
  const factory SettingsDownloadStatus({
    required ModelDownloadStage stage,
    @Default(0) double fraction,
    double? speedBytesPerSec,
    Duration? timeRemaining,
  }) = _SettingsDownloadStatus;
}

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ReaderPreferences globalReaderPrefs,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default({})
    Map<String, ReaderPreferences> documentReaderPrefs,
    @Default(Settings()) Settings appSettings,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<SherpaTtsModelInfo> ttsAvailableModels,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<SherpaTtsModelInfo> ttsInstalledModels,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default({})
    Set<String> ttsDownloadedIds,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default({})
    Map<String, SettingsDownloadStatus> ttsDownloads,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? ttsActiveModelId,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? ttsBusyModelId,
    @JsonKey(includeFromJson: false, includeToJson: false) String? ttsError,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isCheckingTtsUpdates,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? ttsUpdateNotification,
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

  bool isTtsDownloading(String id) => ttsDownloads.containsKey(id);
  bool isTtsDownloaded(String id) => ttsDownloadedIds.contains(id);
  bool isTtsActive(String id) => ttsActiveModelId == id && isTtsDownloaded(id);
  bool isTtsBusy(String id) => ttsBusyModelId == id;

  SettingsDownloadStatus? ttsDownloadOf(String id) => ttsDownloads[id];

  SherpaTtsModelInfo? installedModelById(String id) =>
      ttsInstalledModels.where((m) => m.id == id).firstOrNull;

  bool modelHasUpdate(String id) {
    final installed = installedModelById(id);
    if (installed == null || installed.isCustom) return false;
    final latest = ttsAvailableModels.where((m) => m.id == id).firstOrNull;
    if (latest == null) return false;
    return installed.hasUpdateAvailable(latest);
  }
}
