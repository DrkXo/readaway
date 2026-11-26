import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../app_database.dart';
import '../tables/translation_tables.dart';

part 'translation_dao.g.dart';

@DriftAccessor(tables: [TranslationCacheEntries, CustomTranslatorEntries])
@lazySingleton
class TranslationDao extends DatabaseAccessor<AppDatabase>
    with _$TranslationDaoMixin {
  TranslationDao(super.db);

  /// Retrieves a cached translation by [key].
  Future<TranslationCacheRow?> getTranslation(String key) {
    return (select(
      translationCacheEntries,
    )..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
  }

  /// Inserts or updates a cached translation entry.
  Future<void> putTranslation(TranslationCacheRow entry) {
    return into(translationCacheEntries).insert(
      entry,
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Batch inserts or updates cached translation entries.
  Future<void> putTranslations(List<TranslationCacheRow> entries) {
    return batch((b) {
      b.insertAll(
        translationCacheEntries,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Retrieves all cached translations for a specific chapter in a book.
  Future<List<TranslationCacheRow>> getChapterTranslations({
    required String bookHash,
    required int chapterIndex,
    required String targetLang,
  }) {
    return (select(translationCacheEntries)..where(
          (t) =>
              t.bookHash.equals(bookHash) &
              t.chapterIndex.equals(chapterIndex) &
              t.targetLang.equals(targetLang),
        ))
        .get();
  }

  /// Clears all cached translations.
  Future<int> clearAllTranslations() {
    return delete(translationCacheEntries).go();
  }

  /// Custom translator operations
  Future<List<CustomTranslatorRow>> getCustomTranslators() {
    return select(customTranslatorEntries).get();
  }

  Future<void> saveCustomTranslator(CustomTranslatorRow translator) {
    return into(customTranslatorEntries).insert(
      translator,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> deleteCustomTranslator(String id) {
    return (delete(
      customTranslatorEntries,
    )..where((t) => t.id.equals(id))).go();
  }
}
