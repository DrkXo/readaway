import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../../features/reader/domain/entity/reader_preferences.dart';
import '../app_database.dart';
import '../tables/reader_preferences_table.dart';

part 'reader_preferences_dao.g.dart';

/// Reader preference rows addressed by scope and owner key.
///
/// Scope identities map 1:1 to the removed Hive key scheme:
/// - global → scope `global`, ownerKey `''`
/// - per-path → scope `reader`, ownerKey the document path (legacy key)
/// - per-content → scope `reader`, ownerKey the content sha256
@DriftAccessor(tables: [ReaderPreferenceEntries])
@lazySingleton
class ReaderPreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$ReaderPreferencesDaoMixin {
  ReaderPreferencesDao(super.db);

  static const String globalScope = 'global';
  static const String readerScope = 'reader';
  static const String globalOwnerKey = '';

  /// The stored preferences for [scope]/[ownerKey], or null when absent.
  Future<ReaderPreferences?> get({
    required String scope,
    required String ownerKey,
  }) async {
    final row =
        await (select(readerPreferenceEntries)..where(
              (e) => e.scope.equals(scope) & e.ownerKey.equals(ownerKey),
            ))
            .getSingleOrNull();
    return row?.payload;
  }

  /// Inserts or replaces the preferences row, stamping the write time.
  Future<void> put({
    required String scope,
    required String ownerKind,
    required String ownerKey,
    required ReaderPreferences prefs,
  }) {
    return into(readerPreferenceEntries).insert(
      ReaderPreferenceEntry(
        scope: scope,
        ownerKind: ownerKind,
        ownerKey: ownerKey,
        payload: prefs,
        updatedAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Removes the row for [scope]/[ownerKey].
  Future<void> remove({required String scope, required String ownerKey}) async {
    await (delete(readerPreferenceEntries)..where(
          (e) => e.scope.equals(scope) & e.ownerKey.equals(ownerKey),
        ))
        .go();
  }

  /// Deletes the legacy path-keyed preference for [path] (and only that one).
  ///
  /// Mirrors the old `readerBox.delete('reader_doc_$path')` behaviour: the
  /// content-keyed row is deliberately left alone so settings follow identical
  /// bytes at a new location.
  Future<void> deletePathKeyed(String path) =>
      remove(scope: readerScope, ownerKey: path);

  /// Batch variant of [deletePathKeyed].
  Future<void> deletePathKeyedMany(List<String> paths) async {
    if (paths.isEmpty) return;
    await (delete(readerPreferenceEntries)..where(
          (e) => e.scope.equals(readerScope) & e.ownerKey.isIn(paths),
        ))
        .go();
  }
}
