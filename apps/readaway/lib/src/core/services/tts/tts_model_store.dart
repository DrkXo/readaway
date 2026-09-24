// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:injectable/injectable.dart';

import '../storage/hive/app_storage_service.dart';
import 'tts_models.dart';

/// Persistence and single source of truth for the TTS model catalog, sha256 checksums,
/// and installed/downloaded models index, backed by Hive.
@lazySingleton
class TtsModelStore {
  TtsModelStore({required AppStorageService storage}) : _storage = storage {
    _initStreams();
  }

  final AppStorageService _storage;

  static const String _catalogKey = 'tts_model_catalog';
  static const String _catalogTimestampKey = 'tts_model_catalog_ts';
  static const String _checksumsKey = 'tts_model_checksums';
  static const String _installedKey = 'tts_installed_models';

  final _installedModelsController =
      StreamController<List<SherpaTtsModelInfo>>.broadcast();
  final _downloadedIdsController = StreamController<Set<String>>.broadcast();
  final _catalogController =
      StreamController<List<SherpaTtsModelInfo>>.broadcast();

  void _initStreams() {
    _storage.ttsBox.watch(key: _installedKey).listen((_) {
      final installed = loadInstalledModelsList();
      if (!_installedModelsController.isClosed) {
        _installedModelsController.add(installed);
      }
      if (!_downloadedIdsController.isClosed) {
        _downloadedIdsController.add(installed.map((m) => m.id).toSet());
      }
    });

    _storage.ttsBox.watch(key: _catalogKey).listen((_) {
      if (!_catalogController.isClosed) {
        _catalogController.add(loadCatalog());
      }
    });
  }

  // --- Catalog ---

  /// The persisted catalog, or empty list when none is stored.
  List<SherpaTtsModelInfo> loadCatalog() {
    final raw = _storage.ttsBox.get(_catalogKey);
    if (raw is List) {
      return raw.whereType<SherpaTtsModelInfo>().toList();
    }
    return const [];
  }

  /// Timestamp when catalog was last synced.
  int? get catalogTimestamp =>
      _storage.ttsBox.get(_catalogTimestampKey) as int?;

  /// Finds a model in installed models first, then the catalog by [id].
  SherpaTtsModelInfo? byId(String id) {
    final installed = loadInstalledModels();
    if (installed.containsKey(id)) {
      return installed[id];
    }
    final catalog = loadCatalog();
    for (final m in catalog) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Saves catalog models and notifies all listeners.
  Future<void> saveCatalog(List<SherpaTtsModelInfo> models) async {
    await _storage.ttsBox.put(_catalogKey, models);
    await _storage.ttsBox.put(
      _catalogTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (!_catalogController.isClosed) {
      _catalogController.add(models);
    }
  }

  /// Emits the current catalog immediately on subscription, then any updates.
  Stream<List<SherpaTtsModelInfo>> watchCatalog() async* {
    yield loadCatalog();
    yield* _catalogController.stream;
  }

  // --- Checksums ---

  Map<String, String> loadChecksums() {
    final raw = _storage.ttsBox.get(_checksumsKey);
    if (raw is Map) {
      return raw.cast<String, String>();
    }
    return const {};
  }

  Future<void> saveChecksums(Map<String, String> checksums) async {
    await _storage.ttsBox.put(_checksumsKey, checksums);
  }

  /// sha256 of a release asset by file name, or null when unknown.
  String? checksumFor(String fileName) => loadChecksums()[fileName];

  // --- Installed / Downloaded Models ---

  Map<String, SherpaTtsModelInfo> loadInstalledModels() {
    final raw = _storage.ttsBox.get(_installedKey);
    if (raw is Map) {
      final result = <String, SherpaTtsModelInfo>{};
      for (final entry in raw.entries) {
        if (entry.key is String && entry.value is SherpaTtsModelInfo) {
          result[entry.key as String] = entry.value as SherpaTtsModelInfo;
        }
      }
      return result;
    }
    return const {};
  }

  List<SherpaTtsModelInfo> loadInstalledModelsList() =>
      loadInstalledModels().values.toList();

  Set<String> loadDownloadedIds() => loadInstalledModels().keys.toSet();

  Future<void> saveInstalledModel(SherpaTtsModelInfo model) async {
    final installed = Map<String, SherpaTtsModelInfo>.from(
      loadInstalledModels(),
    );
    installed[model.id] = model;
    await _storage.ttsBox.put(_installedKey, installed);
    if (!_installedModelsController.isClosed) {
      _installedModelsController.add(installed.values.toList());
    }
    if (!_downloadedIdsController.isClosed) {
      _downloadedIdsController.add(installed.keys.toSet());
    }
  }

  Future<void> removeInstalledModel(String modelId) async {
    final installed = Map<String, SherpaTtsModelInfo>.from(
      loadInstalledModels(),
    );
    installed.remove(modelId);
    await _storage.ttsBox.put(_installedKey, installed);
    if (!_installedModelsController.isClosed) {
      _installedModelsController.add(installed.values.toList());
    }
    if (!_downloadedIdsController.isClosed) {
      _downloadedIdsController.add(installed.keys.toSet());
    }
  }

  /// Backward-compatible alias for markDownloaded.
  Future<void> markDownloaded(String modelId) async {
    final model = byId(modelId);
    if (model != null) {
      await saveInstalledModel(model);
    }
  }

  /// Backward-compatible alias for unmarkDownloaded.
  Future<void> unmarkDownloaded(String modelId) async {
    await removeInstalledModel(modelId);
  }

  /// Emits the list of installed models immediately on subscription, then any updates.
  Stream<List<SherpaTtsModelInfo>> watchInstalledModels() async* {
    yield loadInstalledModelsList();
    yield* _installedModelsController.stream;
  }

  /// Emits the set of downloaded IDs immediately on subscription, then any updates.
  Stream<Set<String>> watchDownloadedIds() async* {
    yield loadDownloadedIds();
    yield* _downloadedIdsController.stream;
  }

  @disposeMethod
  void dispose() {
    _installedModelsController.close();
    _downloadedIdsController.close();
    _catalogController.close();
  }
}
