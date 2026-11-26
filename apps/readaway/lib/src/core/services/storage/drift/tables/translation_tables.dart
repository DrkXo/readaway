import 'package:drift/drift.dart';

/// Cached translations table for persistent offline storage.
@DataClassName('TranslationCacheRow')
class TranslationCacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get originalText => text()();
  TextColumn get translatedText => text()();
  TextColumn get sourceLang => text()();
  TextColumn get targetLang => text()();
  TextColumn get engineId => text()();
  TextColumn get bookHash => text().nullable()();
  IntColumn get chapterIndex => integer().nullable()();
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

/// Custom OpenAI-compatible endpoints table.
@DataClassName('CustomTranslatorRow')
class CustomTranslatorEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseUrl => text()();
  TextColumn get apiKey => text().nullable()();
  TextColumn get model => text()();
  RealColumn get temperature => real().withDefault(const Constant(0.3))();
  TextColumn get thinkingMode => text().withDefault(const Constant('off'))();
  TextColumn get promptTemplate => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
