import 'dart:async';

import 'package:injectable/injectable.dart';

import '../storage/hive/app_storage_service.dart';
import 'tts_models.dart';

/// Persistence and single source of truth for the TTS model catalog, sha256 checksums,
/// and downloaded models index, backed by Hive.
@lazySingleton
class TtsModelStore {
  TtsModelStore({required this._storage}) {
    _initStreams();
  }

  final AppStorageService _storage;

  static const String _catalogKey = 'tts_model_catalog';
  static const String _catalogTimestampKey = 'tts_model_catalog_ts';
  static const String _checksumsKey = 'tts_model_checksums';
  static const String _downloadedKey = 'tts_downloaded_models';

  final _downloadedIdsController = StreamController<Set<String>>.broadcast();
  final _catalogController =
      StreamController<List<SherpaTtsModelInfo>>.broadcast();

  void _initStreams() {
    _storage.ttsBox.watch(key: _downloadedKey).listen((_) {
      if (!_downloadedIdsController.isClosed) {
        _downloadedIdsController.add(loadDownloadedIds());
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

  /// Finds a model in the cached catalog by [id].
  SherpaTtsModelInfo? byId(String id) {
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

  // --- Downloaded model ids ---

  Set<String> loadDownloadedIds() {
    final raw = _storage.ttsBox.get(_downloadedKey);
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return const {};
  }

  Future<void> markDownloaded(String modelId) async {
    final ids = loadDownloadedIds().toSet()..add(modelId);
    await _storage.ttsBox.put(_downloadedKey, ids.toList());
    if (!_downloadedIdsController.isClosed) {
      _downloadedIdsController.add(ids);
    }
  }

  Future<void> unmarkDownloaded(String modelId) async {
    final ids = loadDownloadedIds().toSet()..remove(modelId);
    await _storage.ttsBox.put(_downloadedKey, ids.toList());
    if (!_downloadedIdsController.isClosed) {
      _downloadedIdsController.add(ids);
    }
  }

  /// Emits the current downloaded IDs immediately on subscription, then any updates.
  Stream<Set<String>> watchDownloadedIds() async* {
    yield loadDownloadedIds();
    yield* _downloadedIdsController.stream;
  }

  @disposeMethod
  void dispose() {
    _downloadedIdsController.close();
    _catalogController.close();
  }
}
