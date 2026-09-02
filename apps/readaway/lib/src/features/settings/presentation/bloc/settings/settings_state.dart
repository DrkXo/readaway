part of 'settings_bloc.dart';

@freezed
abstract class SettingsDownloadStatus with _$SettingsDownloadStatus {
  const factory SettingsDownloadStatus({
    required ModelDownloadStage stage,
    @Default(0) double fraction,
  }) = _SettingsDownloadStatus;
}

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ReaderPreferences globalReaderPrefs,
    required Map<String, ReaderPreferences> documentReaderPrefs,
    String? activeDocumentPath,
    @Default(Settings()) Settings appSettings,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<SherpaTtsModelInfo> ttsAvailableModels,
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
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}

extension SettingsStateX on SettingsState {
  ReaderPreferences resolvedReaderPrefs(String? documentPath) {
    if (documentPath == null ||
        !documentReaderPrefs.containsKey(documentPath)) {
      return globalReaderPrefs;
    }
    final docJson = documentReaderPrefs[documentPath]!.toJson();
    final merged = Map<String, dynamic>.from(globalReaderPrefs.toJson());
    for (final entry in docJson.entries) {
      if (entry.value != null) merged[entry.key] = entry.value;
    }
    return ReaderPreferences.fromJson(merged);
  }

  bool isTtsDownloading(String id) => ttsDownloads.containsKey(id);
  bool isTtsDownloaded(String id) => ttsDownloadedIds.contains(id);
  bool isTtsActive(String id) => ttsActiveModelId == id && isTtsDownloaded(id);
  bool isTtsBusy(String id) => ttsBusyModelId == id;

  SettingsDownloadStatus? ttsDownloadOf(String id) => ttsDownloads[id];
}
