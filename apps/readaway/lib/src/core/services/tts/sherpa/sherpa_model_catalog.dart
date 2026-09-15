import 'package:injectable/injectable.dart';

import '../tts_model_store.dart';
import '../tts_models.dart';
import 'sherpa_tts_api.dart';

@lazySingleton
class SherpaTtsModelCatalogService {
  SherpaTtsModelCatalogService({
    required this._api,
    required this._store,
  });

  final SherpaTtsApi _api;
  final TtsModelStore _store;

  List<SherpaTtsModelInfo> _models = const [];
  List<SherpaTtsModelInfo> get models => _models;

  Map<String, String> _checksums = const {};

  /// sha256 of a release asset by file name, or null when the checksum file
  /// hasn't been fetched (or doesn't list that file).
  String? checksumFor(String fileName) => _checksums[fileName];

  /// Shared espeak-ng phonemization data URL (owned by the API layer).
  String get espeakDataUrl => _api.espeakDataUrl;

  /// Loads the catalog from the persisted store when fresh (offline-friendly),
  /// otherwise fetches the live manifest, parses it via
  /// [SherpaTtsModelInfo.fromAsset], and persists it. Never throws: on
  /// failure the catalog stays empty (the UI surfaces the error) so a
  /// transient network problem can't take down app startup.
  Future<void> load() async {
    if (_models.isNotEmpty) return;

    // 1. Prefer the persisted catalog when it's fresh (offline startup).
    final cached = _store.loadCatalog();
    if (cached != null && cached.isNotEmpty && _store.isCatalogFresh()) {
      _models = cached;
      _checksums = _store.loadChecksums();
      return;
    }

    // 2. Otherwise fetch the live manifest.
    final assets = await _api.fetchManifest();
    final parsed = <SherpaTtsModelInfo>[];
    for (final a in assets) {
      final name = a['name'] as String?;
      final size = (a['size'] as num?)?.toInt();
      final downloadUrl = a['browser_download_url'] as String?;
      if (name == null || size == null || downloadUrl == null) continue;
      final m = SherpaTtsModelInfo.fromAsset(
        name: name,
        sizeBytes: size,
        downloadUrl: downloadUrl,
        hifiganUrl: _api.hifiganUrl,
      );
      if (m != null) parsed.add(m);
    }

    // 3. If the network failed but a stale persisted catalog exists, keep it
    //    rather than showing an empty list.
    if (parsed.isEmpty && cached != null && cached.isNotEmpty) {
      _models = cached;
      _checksums = _store.loadChecksums();
      return;
    }

    parsed.sort((a, b) {
      final c = a.languageLabel.compareTo(b.languageLabel);
      return c != 0 ? c : a.displayName.compareTo(b.displayName);
    });
    _models = parsed;

    _checksums = await _api.fetchChecksums();

    // 4. Persist for offline startup.
    if (_models.isNotEmpty) {
      await _store.saveCatalog(_models);
      await _store.saveChecksums(_checksums);
    }
  }

  SherpaTtsModelInfo? byId(String id) {
    for (final m in _models) {
      if (m.id == id) return m;
    }
    return null;
  }
}
