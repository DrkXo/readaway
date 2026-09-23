import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/tts/tts_models.dart';

/// Contract for discovering, downloading, activating, and previewing TTS models.
abstract interface class TtsModelRepository {
  /// Fetches the model catalog. When [forceRefresh] is false, returns the cached
  /// catalog from local storage (or fetches from remote if storage is empty).
  /// When [forceRefresh] is true, fetches fresh data from remote and updates storage.
  TaskEither<Failure, List<SherpaTtsModelInfo>> getCatalog({
    bool forceRefresh = false,
  });

  /// Streams the list of available catalog models reactively.
  Stream<List<SherpaTtsModelInfo>> watchCatalog();

  /// Streams the set of downloaded model IDs reactively.
  Stream<Set<String>> watchDownloadedModelIds();

  /// All catalog models currently in local storage.
  List<SherpaTtsModelInfo> get availableModels;

  /// IDs of models currently downloaded and available offline.
  TaskEither<Failure, Set<String>> getDownloadedModelIds();

  /// The currently loaded model ID, if any.
  String? get activeModelId;

  /// Loads and activates a model by [modelId].
  TaskEither<Failure, Unit> activateModel(String modelId);

  /// Downloads and extracts a model, emitting progress updates.
  Stream<ModelDownloadProgress> downloadModel(SherpaTtsModelInfo model);

  /// Pauses an in-progress download of [modelId].
  Future<void> pauseDownload(String modelId);

  /// Resumes a paused download of [modelId].
  Future<void> resumeDownload(String modelId);

  /// Cancels an in-progress download of [modelId].
  Future<void> cancelDownload(String modelId);

  /// Deletes a downloaded model from disk and updates storage.
  TaskEither<Failure, Unit> deleteModel(String modelId);

  /// Generates a brief spoken sample and plays it back as an audio preview.
  TaskEither<Failure, Unit> playPreview(String modelId);

  /// Stops any currently playing audio preview.
  TaskEither<Failure, Unit> stopPreview();
}
