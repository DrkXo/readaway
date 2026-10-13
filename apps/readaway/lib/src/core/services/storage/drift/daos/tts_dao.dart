import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../tts/tts_models.dart';
import '../app_database.dart';
import '../tables/tts_tables.dart';

part 'tts_dao.g.dart';

/// Persists the TTS catalog, checksums and installed-model index.
///
/// The catalog is replaced wholesale on sync (a transaction that never touches
/// installation metadata); installed models and checksums are single-row
/// operations.
@DriftAccessor(
  tables: [
    TtsCatalogModels,
    TtsInstalledModels,
    TtsChecksums,
    TtsMeta,
  ],
)
@lazySingleton
class TtsDao extends DatabaseAccessor<AppDatabase> with _$TtsDaoMixin {
  TtsDao(super.db);

  // --- Catalog ---

  /// Catalog models in display order.
  Future<List<SherpaTtsModelInfo>> loadCatalog() async {
    final rows = await (select(
      ttsCatalogModels,
    )..orderBy([(t) => OrderingTerm.asc(t.sortIndex)])).get();
    return [for (final row in rows) row.payload];
  }

  /// Milliseconds since epoch of the last catalog sync, or null.
  Future<int?> catalogTimestamp() async {
    final latest =
        await (select(ttsCatalogModels)
              ..orderBy([(t) => OrderingTerm.desc(t.syncedAt)])
              ..limit(1))
            .getSingleOrNull();
    return latest?.syncedAt;
  }

  /// Replaces the catalog, preserving installation metadata untouched.
  Future<void> saveCatalog(List<SherpaTtsModelInfo> models) {
    return transaction(() async {
      await delete(ttsCatalogModels).go();
      final syncedAt = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < models.length; i++) {
        await into(ttsCatalogModels).insert(
          TtsCatalogModelRow(
            id: models[i].id,
            payload: models[i],
            sortIndex: i,
            syncedAt: syncedAt,
          ),
        );
      }
    });
  }

  /// Emits the catalog in display order on every change.
  Stream<List<SherpaTtsModelInfo>> watchCatalog() {
    return (select(ttsCatalogModels)
          ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
        .watch()
        .map((rows) => [for (final row in rows) row.payload]);
  }

  // --- Checksums ---

  Future<Map<String, String>> loadChecksums() async {
    final rows = await select(ttsChecksums).get();
    return {for (final row in rows) row.fileName: row.sha256};
  }

  /// Replaces the whole checksum map.
  Future<void> saveChecksums(Map<String, String> checksums) {
    return transaction(() async {
      await delete(ttsChecksums).go();
      for (final entry in checksums.entries) {
        await into(ttsChecksums).insert(
          TtsChecksumRow(fileName: entry.key, sha256: entry.value),
        );
      }
    });
  }

  // --- Installed models ---

  Future<Map<String, SherpaTtsModelInfo>> loadInstalledModels() async {
    final rows = await (select(
      ttsInstalledModels,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return {for (final row in rows) row.id: row.payload};
  }

  Future<void> saveInstalledModel(SherpaTtsModelInfo model) {
    return into(ttsInstalledModels).insert(
      TtsInstalledModelRow(
        id: model.id,
        payload: model,
        installedAt: model.installedAt ?? DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeInstalledModel(String modelId) async {
    await (delete(ttsInstalledModels)..where((t) => t.id.equals(modelId))).go();
  }

  /// Emits the installed models on every change.
  Stream<List<SherpaTtsModelInfo>> watchInstalledModels() {
    return (select(ttsInstalledModels)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map((rows) => [for (final row in rows) row.payload]);
  }
}
