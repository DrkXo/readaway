import 'dart:convert';

import 'package:cacherine/cacherine.dart';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/storage/drift/app_database.dart';
import '../../../../core/services/storage/drift/daos/translation_dao.dart';
import '../../domain/entity/translation_models.dart';
import '../../domain/repositories/translation_cache_repository.dart';

@LazySingleton(as: TranslationCacheRepository)
class TranslationCacheRepositoryImpl implements TranslationCacheRepository {
  TranslationCacheRepositoryImpl(this._dao);

  final TranslationDao _dao;
  final SimpleLRUCache<String, TranslationResult> _memoryCache =
      SimpleLRUCache<String, TranslationResult>(500);

  @override
  String buildKey({
    required String engineId,
    required String sourceLang,
    required String targetLang,
    required String text,
  }) {
    final hash = md5.convert(utf8.encode(text.trim())).toString();
    return '$engineId:$sourceLang:$targetLang:$hash';
  }

  @override
  Future<TranslationResult?> get(String key) async {
    final memoryHit = _memoryCache.get(key);
    if (memoryHit != null) {
      return TranslationResult(
        originalText: memoryHit.originalText,
        translatedText: memoryHit.translatedText,
        sourceLang: memoryHit.sourceLang,
        targetLang: memoryHit.targetLang,
        engineId: memoryHit.engineId,
        isCacheHit: true,
      );
    }

    final row = await _dao.getTranslation(key);
    if (row != null) {
      final result = TranslationResult(
        originalText: row.originalText,
        translatedText: row.translatedText,
        sourceLang: row.sourceLang,
        targetLang: row.targetLang,
        engineId: row.engineId,
        isCacheHit: true,
      );
      _memoryCache.set(key, result);
      return result;
    }

    return null;
  }

  @override
  Future<void> put(
    TranslationResult result, {
    String? bookHash,
    int? chapterIndex,
  }) async {
    final key = buildKey(
      engineId: result.engineId,
      sourceLang: result.sourceLang,
      targetLang: result.targetLang,
      text: result.originalText,
    );

    _memoryCache.set(key, result);

    await _dao.putTranslation(
      TranslationCacheRow(
        cacheKey: key,
        originalText: result.originalText,
        translatedText: result.translatedText,
        sourceLang: result.sourceLang,
        targetLang: result.targetLang,
        engineId: result.engineId,
        bookHash: bookHash,
        chapterIndex: chapterIndex,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> putBatch(
    List<TranslationResult> results, {
    String? bookHash,
    int? chapterIndex,
  }) async {
    if (results.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = <TranslationCacheRow>[];

    for (final res in results) {
      final key = buildKey(
        engineId: res.engineId,
        sourceLang: res.sourceLang,
        targetLang: res.targetLang,
        text: res.originalText,
      );
      _memoryCache.set(key, res);
      rows.add(
        TranslationCacheRow(
          cacheKey: key,
          originalText: res.originalText,
          translatedText: res.translatedText,
          sourceLang: res.sourceLang,
          targetLang: res.targetLang,
          engineId: res.engineId,
          bookHash: bookHash,
          chapterIndex: chapterIndex,
          timestamp: now,
        ),
      );
    }

    await _dao.putTranslations(rows);
  }

  @override
  Future<Map<String, String>> getChapterTranslations({
    required String bookHash,
    required int chapterIndex,
    required String targetLang,
  }) async {
    final rows = await _dao.getChapterTranslations(
      bookHash: bookHash,
      chapterIndex: chapterIndex,
      targetLang: targetLang,
    );

    final map = <String, String>{};
    for (final row in rows) {
      map[row.originalText] = row.translatedText;
      final key = buildKey(
        engineId: row.engineId,
        sourceLang: row.sourceLang,
        targetLang: row.targetLang,
        text: row.originalText,
      );
      _memoryCache.set(
        key,
        TranslationResult(
          originalText: row.originalText,
          translatedText: row.translatedText,
          sourceLang: row.sourceLang,
          targetLang: row.targetLang,
          engineId: row.engineId,
          isCacheHit: true,
        ),
      );
    }
    return map;
  }

  @override
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _dao.clearAllTranslations();
  }
}
