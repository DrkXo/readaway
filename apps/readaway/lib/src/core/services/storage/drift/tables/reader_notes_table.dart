import 'package:drift/drift.dart';

/// One row per reader bookmark, highlight or note.
///
/// Deliberately **not** a foreign key of the documents table: a document opened
/// directly (`pickDocumentWithoutSaving`) can be annotated without ever
/// entering the library, and removing a document from the library leaves its
/// annotations in place. Annotations are therefore keyed by `documentPath`
/// alone, which is exactly today's behaviour.
@DataClassName('ReaderNoteRow')
@TableIndex(name: 'idx_reader_notes_document', columns: {#documentPath})
@TableIndex(
  name: 'idx_reader_notes_document_type',
  columns: {#documentPath, #type},
)
@TableIndex(
  name: 'idx_reader_notes_document_chapter',
  columns: {#documentPath, #chapterIndex},
)
@TableIndex(name: 'idx_reader_notes_updated', columns: {#updatedAt})
@TableIndex(name: 'idx_reader_notes_deleted', columns: {#deletedAt})
class ReaderNotes extends Table {
  /// The [ReaderNote.id] (uuid).
  TextColumn get id => text()();
  TextColumn get documentPath => text()();

  /// `bookmark` | `highlight` | `note`.
  TextColumn get type => text()();

  /// `reflowable` | `page`.
  TextColumn get anchorKind =>
      text().withDefault(const Constant('reflowable'))();
  IntColumn get chapterIndex => integer().withDefault(const Constant(0))();
  IntColumn get startChar => integer().withDefault(const Constant(0))();
  IntColumn get endChar => integer().withDefault(const Constant(0))();
  IntColumn get pageIndex => integer().withDefault(const Constant(0))();
  TextColumn get anchorText => text().withDefault(const Constant(''))();
  TextColumn get anchorPrefix => text().withDefault(const Constant(''))();
  TextColumn get anchorSuffix => text().withDefault(const Constant(''))();
  BoolColumn get orphaned => boolean().withDefault(const Constant(false))();

  /// `highlight` | `underline` | `squiggly`.
  TextColumn get style => text().withDefault(const Constant('highlight'))();
  TextColumn get colorValue => text().withDefault(const Constant('amber'))();
  TextColumn get note => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft-delete tombstone. A non-null value hides the note but keeps it for
  /// undo and future sync.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
