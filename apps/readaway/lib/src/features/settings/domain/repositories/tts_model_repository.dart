import '../../../../core/result/result.dart';
import '../../../../core/services/tts/catalog/tts_catalog_service.dart';
import '../../../../core/services/tts/importer/custom_tts_model_importer_service.dart';
import '../../../../core/services/tts/tts_models.dart';

/// Contract for discovering, activating, previewing, and importing TTS models.
///
/// Downloading is *not* here: `TtsDownloadManager` is the single owner of the
/// install pipeline and the only writer of installed state, so callers observe
/// it through its `snapshots` stream instead of a repository method.
abstract interface class TtsModelRepository {
  /// Fetches the model catalog. When [forceRefresh] is false, returns the cached
  /// or bundled catalog from local storage without network latency.
  /// When [forceRefresh] is true, checks upstream GitHub for updates.
  Future<Result<List<SherpaTtsModelInfo>>> getCatalog({
    bool forceRefresh = false,
  });

  /// Streams the list of available catalog models reactively.
  Stream<List<SherpaTtsModelInfo>> watchCatalog();

  /// Streams the list of installed (downloaded + custom) models reactively.
  Stream<List<SherpaTtsModelInfo>> watchInstalledModels();

  /// All catalog models currently in local storage.
  List<SherpaTtsModelInfo> get availableModels;

  /// Full list of installed (downloaded and custom) models.
  Future<Result<List<SherpaTtsModelInfo>>> getInstalledModels();

  /// The currently loaded model ID, if any.
  String? get activeModelId;

  /// Loads and activates a model by [modelId].
  Future<Result<void>> activateModel(String modelId);

  /// Deletes a downloaded model from disk and updates storage.
  Future<Result<void>> deleteModel(String modelId);

  /// Checks upstream for newly released or updated models.
  Future<Result<TtsCatalogSyncResult>> checkForCatalogUpdates();

  /// Inspects a local archive (.zip, .tar.bz2, .tar.gz) or folder to detect model compatibility.
  Future<Result<CustomModelInspectionResult>> inspectCustomModel(
    String sourcePath,
  );

  /// Imports an inspected custom model into Readaway storage.
  Future<Result<SherpaTtsModelInfo>> importCustomModel({
    required CustomModelInspectionResult inspection,
    required String displayName,
    required String languageCode,
    required String languageLabel,
    SherpaTtsModelType? typeOverride,
    int speakerCount = 0,
    int sampleRate = 22050,
  });

  /// Generates a brief spoken sample and plays it back as an audio preview.
  Future<Result<void>> playPreview(String modelId);

  /// Stops any currently playing audio preview.
  Future<Result<void>> stopPreview();
}
