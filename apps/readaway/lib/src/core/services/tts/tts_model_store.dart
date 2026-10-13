// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:injectable/injectable.dart';

import '../storage/drift/daos/tts_dao.dart';
import 'tts_models.dart';

/// Persistence and single source of truth for the TTS model catalog, sha256
/// checksums, and installed/downloaded models index, backed by the drift
/// database.
///
/// The public surface stays synchronous: caches are hydrated by [init] (DI
/// awaits it) and kept in sync from the database `watch()` streams, so reads
/// never block and callers that used the old synchronous Hive reads keep
/// working unchanged.
@lazySingleton
class TtsModelStore {
  TtsModelStore(this._dao) {
    _initStreams();
  }

  final TtsDao _dao;

  List<SherpaTtsModelInfo> _catalog = const [];
  int? _catalogTimestamp;
  Map<String, String> _checksums = const {};
  Map<String, SherpaTtsModelInfo> _installed = const {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final _installedModelsController =
      StreamController<List<SherpaTtsModelInfo>>.broadcast();
  final _catalogController =
      StreamController<List<SherpaTtsModelInfo>>.broadcast();

  /// Loads the persisted state into the in-memory caches.
  ///
  /// Resolved before the store is handed out through DI; call it explicitly
  /// when constructing the store directly in tests.
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final results = await Future.wait<Object?>([
      _dao.loadCatalog(),
      _dao.catalogTimestamp(),
      _dao.loadChecksums(),
      _dao.loadInstalledModels(),
    ]);
    _catalog = results[0] as List<SherpaTtsModelInfo>;
    _catalogTimestamp = results[1] as int?;
    _checksums = results[2] as Map<String, String>;
    _installed = results[3] as Map<String, SherpaTtsModelInfo>;
  }

  void _initStreams() {
    _subscriptions.add(
      _dao.watchInstalledModels().listen((installed) {
        _installed = {for (final model in installed) model.id: model};
        if (!_installedModelsController.isClosed) {
          _installedModelsController.add(installed);
        }
      }),
    );

    _subscriptions.add(
      _dao.watchCatalog().listen((catalog) {
        _catalog = catalog;
        if (!_catalogController.isClosed) {
          _catalogController.add(catalog);
        }
      }),
    );
  }

  // --- Catalog ---

  /// The persisted catalog, or empty list when none is stored.
  List<SherpaTtsModelInfo> loadCatalog() => _catalog;

  /// Timestamp when catalog was last synced.
  int? get catalogTimestamp => _catalogTimestamp;

  /// Finds a model in installed models first, then the catalog by [id].
  SherpaTtsModelInfo? byId(String id) {
    final installed = _installed[id];
    if (installed != null) return installed;
    for (final model in _catalog) {
      if (model.id == id) return model;
    }
    return null;
  }

  /// Saves catalog models and notifies all listeners.
  Future<void> saveCatalog(List<SherpaTtsModelInfo> models) async {
    await _dao.saveCatalog(models);
    _catalog = List.unmodifiable(models);
    _catalogTimestamp = DateTime.now().millisecondsSinceEpoch;
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

  Map<String, String> loadChecksums() => _checksums;

  Future<void> saveChecksums(Map<String, String> checksums) async {
    await _dao.saveChecksums(checksums);
    _checksums = Map.unmodifiable(checksums);
  }

  /// sha256 of a release asset by file name, or null when unknown.
  String? checksumFor(String fileName) => _checksums[fileName];

  // --- Installed / Downloaded Models ---

  Map<String, SherpaTtsModelInfo> loadInstalledModels() => _installed;

  List<SherpaTtsModelInfo> loadInstalledModelsList() =>
      _installed.values.toList();

  Set<String> loadDownloadedIds() => _installed.keys.toSet();

  Future<void> saveInstalledModel(SherpaTtsModelInfo model) async {
    await _dao.saveInstalledModel(model);
    final updated = Map<String, SherpaTtsModelInfo>.from(_installed)
      ..[model.id] = model;
    _installed = updated;
    if (!_installedModelsController.isClosed) {
      _installedModelsController.add(updated.values.toList());
    }
  }

  Future<void> removeInstalledModel(String modelId) async {
    await _dao.removeInstalledModel(modelId);
    final updated = Map<String, SherpaTtsModelInfo>.from(_installed)
      ..remove(modelId);
    _installed = updated;
    if (!_installedModelsController.isClosed) {
      _installedModelsController.add(updated.values.toList());
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

  @disposeMethod
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _installedModelsController.close();
    _catalogController.close();
  }
}
