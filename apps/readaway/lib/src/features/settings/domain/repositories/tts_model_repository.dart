import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/tts/tts_models.dart';

/// Contract for discovering, downloading, activating, and previewing TTS models.
abstract interface class TtsModelRepository {
  /// All catalog models available for downloading.
  List<SherpaTtsModelInfo> get availableModels;

  /// IDs of models currently downloaded and available offline.
  TaskEither<Failure, Set<String>> getDownloadedModelIds();

  /// The currently loaded model ID, if any.
  String? get activeModelId;

  /// Loads and activates a model by [modelId].
  TaskEither<Failure, Unit> activateModel(String modelId);

  /// Downloads and extracts a model, emitting progress updates.
  Stream<ModelDownloadProgress> downloadModel(SherpaTtsModelInfo model);

  /// Deletes a downloaded model from disk.
  TaskEither<Failure, Unit> deleteModel(String modelId);

  /// Generates a brief spoken sample and plays it back as an audio preview.
  TaskEither<Failure, Unit> playPreview(String modelId);
}
