import '../entity/translation_models.dart';

abstract class TranslationCacheRepository {
  /// Generates a standardized cache key.
  String buildKey({
    required String engineId,
    required String sourceLang,
    required String targetLang,
    required String text,
  });

  /// Retrieves a cached translation result by [key].
  Future<TranslationResult?> get(String key);

  /// Stores a single translation result in cache.
  Future<void> put(
    TranslationResult result, {
    String? bookHash,
    int? chapterIndex,
  });

  /// Stores multiple translation results in cache.
  Future<void> putBatch(
    List<TranslationResult> results, {
    String? bookHash,
    int? chapterIndex,
  });

  /// Retrieves all cached translations for a chapter.
  Future<Map<String, String>> getChapterTranslations({
    required String bookHash,
    required int chapterIndex,
    required String targetLang,
  });

  /// Clears the entire translation cache.
  Future<void> clearAll();
}
