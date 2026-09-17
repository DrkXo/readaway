import 'package:injectable/injectable.dart';

import '../storage/hive/app_storage_service.dart';
import 'tts_models.dart';

/// Persistence for the TTS model catalog and downloaded-model index, backed
/// by the app's Hive store. The catalog is a fast, offline-friendly cache of
/// the live GitHub manifest; the downloaded-id set is a fast index that is
/// verified against the filesystem on read (the filesystem stays the source
/// of truth).
@lazySingleton
class TtsModelStore {
  TtsModelStore({required this._storage});

  final AppStorageService _storage;

  static const String _catalogKey = 'tts_model_catalog';
  static const String _catalogTimestampKey = 'tts_model_catalog_ts';
  static const String _checksumsKey = 'tts_model_checksums';
  static const String _downloadedKey = 'tts_downloaded_models';

  /// How long a persisted catalog is considered fresh before the app
  /// re-fetches the live manifest.
  static const Duration catalogFreshness = Duration(days: 1);

  // --- Catalog ---

  /// The persisted catalog, or null when none is stored (or it failed to
  /// decode).
  List<SherpaTtsModelInfo>? loadCatalog() {
    final raw = _storage.ttsBox.get(_catalogKey);
    if (raw is List) {
      return raw.whereType<SherpaTtsModelInfo>().toList();
    }
    return null;
  }

  Future<void> saveCatalog(List<SherpaTtsModelInfo> models) async {
    await _storage.ttsBox.put(_catalogKey, models);
    await _storage.ttsBox.put(
      _catalogTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Whether the persisted catalog was written within [catalogFreshness].
  bool isCatalogFresh() {
    final ts = _storage.ttsBox.get(_catalogTimestampKey) as int?;
    if (ts == null) return false;
    return DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(ts),
        ) <
        catalogFreshness;
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

  // --- Downloaded model ids ---

  Set<String> loadDownloadedIds() {
    final raw = _storage.ttsBox.get(_downloadedKey);
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return {};
  }

  Future<void> markDownloaded(String modelId) async {
    final ids = loadDownloadedIds()..add(modelId);
    await _storage.ttsBox.put(_downloadedKey, ids.toList());
  }

  Future<void> unmarkDownloaded(String modelId) async {
    final ids = loadDownloadedIds()..remove(modelId);
    await _storage.ttsBox.put(_downloadedKey, ids.toList());
  }
}
