import 'package:drift/drift.dart';

/// Library records.
///
/// Keyed by [path], which is the document identity used throughout the app
/// (library, annotations and the legacy reader-preference keys). There is no
/// rename flow, so a surrogate key would only add a resolution step.
@DataClassName('DocumentRow')
@TableIndex(name: 'idx_documents_last_opened', columns: {#lastOpened})
@TableIndex(name: 'idx_documents_date_added', columns: {#dateAdded})
@TableIndex(name: 'idx_documents_reading_status', columns: {#readingStatus})
@TableIndex(name: 'idx_documents_is_favorite', columns: {#isFavorite})
class Documents extends Table {
  TextColumn get path => text()();
  TextColumn get fileName => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get lastOpened => dateTime()();
  IntColumn get fileSize => integer()();
  TextColumn get format => text()();

  // Reading progress. Kept inline: the row is small and the domain always
  // resolves a document as a single aggregate.
  IntColumn get lastReadPage => integer().withDefault(const Constant(0))();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  IntColumn get lastReadChapter => integer().withDefault(const Constant(0))();
  RealColumn get lastReadProgression => real().withDefault(const Constant(0))();
  TextColumn get readingStatus =>
      text().withDefault(const Constant('unread'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get coverPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {path};
}

/// Many-to-many join between documents and their tags.
///
/// Normalized (rather than a JSON list on [Documents]) so future tag filtering
/// is an indexed lookup instead of a full scan. Distinct tag names are derived
/// with `SELECT DISTINCT tag`, so there is no separate tag table to keep in
/// sync.
@DataClassName('DocumentTagRow')
@TableIndex(name: 'idx_document_tags_tag', columns: {#tag})
class DocumentTags extends Table {
  TextColumn get documentPath =>
      text().references(Documents, #path, onDelete: KeyAction.cascade)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {documentPath, tag};
}
