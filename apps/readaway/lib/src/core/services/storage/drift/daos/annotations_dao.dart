import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../../features/annotations/domain/entity/document_notes.dart';
import '../../../../../features/annotations/domain/entity/reader_note.dart';
import '../app_database.dart';
import '../tables/reader_notes_table.dart';

part 'annotations_dao.g.dart';

/// Persists bookmarks, highlights and notes one row per note.
///
/// The document record is reconstructed on read: `updatedAt` is the newest
/// note change and notes come back in creation order (`createdAt`, then `id`
/// as a tie-breaker). Rows are intentionally keyed by document path without a
/// foreign key to the documents table, so directly-opened documents can hold
/// annotations and library removals leave them in place.
@DriftAccessor(tables: [ReaderNotes])
@lazySingleton
class AnnotationsDao extends DatabaseAccessor<AppDatabase>
    with _$AnnotationsDaoMixin {
  AnnotationsDao(super.db);

  /// The stored notes for [documentPath], or null when it has none.
  Future<DocumentNotes?> readForDocument(String documentPath) async {
    final rows = await _notesFor(documentPath).get();
    if (rows.isEmpty) return null;
    return _toRecord(documentPath, rows);
  }

  /// Every stored record, grouped by document path.
  Future<List<DocumentNotes>> readAll() async {
    final rows =
        await (select(readerNotes)..orderBy([
              (n) => OrderingTerm.asc(n.createdAt),
              (n) => OrderingTerm.asc(n.id),
            ]))
            .get();
    final byPath = <String, List<ReaderNoteRow>>{};
    final order = <String>[];
    for (final row in rows) {
      byPath
          .putIfAbsent(row.documentPath, () {
            order.add(row.documentPath);
            return <ReaderNoteRow>[];
          })
          .add(row);
    }
    return [for (final path in order) _toRecord(path, byPath[path]!)];
  }

  /// Replaces the whole note list of [record.documentPath] atomically.
  Future<void> write(DocumentNotes record) {
    return transaction(() async {
      await (delete(
        readerNotes,
      )..where((n) => n.documentPath.equals(record.documentPath))).go();
      for (final note in record.notes) {
        await into(readerNotes).insert(_toRow(record.documentPath, note));
      }
    });
  }

  /// Drops every note for [documentPath]. A no-op when absent.
  Future<void> removeForDocument(String documentPath) async {
    await (delete(
      readerNotes,
    )..where((n) => n.documentPath.equals(documentPath))).go();
  }

  SimpleSelectStatement<$ReaderNotesTable, ReaderNoteRow> _notesFor(
    String documentPath,
  ) {
    return (select(readerNotes)
      ..where((n) => n.documentPath.equals(documentPath))
      ..orderBy([
        (n) => OrderingTerm.asc(n.createdAt),
        (n) => OrderingTerm.asc(n.id),
      ]));
  }

  ReaderNoteRow _toRow(String documentPath, ReaderNote note) => ReaderNoteRow(
    id: note.id,
    documentPath: documentPath,
    type: note.type.name,
    anchorKind: note.anchor.kind.name,
    chapterIndex: note.anchor.chapterIndex,
    startChar: note.anchor.startChar,
    endChar: note.anchor.endChar,
    pageIndex: note.anchor.pageIndex,
    anchorText: note.anchor.text,
    anchorPrefix: note.anchor.prefix,
    anchorSuffix: note.anchor.suffix,
    orphaned: note.anchor.orphaned,
    style: note.style.name,
    colorValue: note.colorValue,
    note: note.note,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    deletedAt: note.deletedAt,
  );

  DocumentNotes _toRecord(String documentPath, List<ReaderNoteRow> rows) {
    final notes = [for (final row in rows) _toNote(row)];
    return DocumentNotes(
      documentPath: documentPath,
      schemaVersion: kDocumentNotesSchemaVersion,
      notes: notes,
      updatedAt: notes
          .map((note) => note.updatedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  ReaderNote _toNote(ReaderNoteRow row) => ReaderNote(
    id: row.id,
    type: _enumByName(ReaderNoteType.values, row.type, ReaderNoteType.bookmark),
    anchor: ReaderNoteAnchor(
      kind: _enumByName(
        NoteAnchorKind.values,
        row.anchorKind,
        NoteAnchorKind.reflowable,
      ),
      chapterIndex: row.chapterIndex,
      startChar: row.startChar,
      endChar: row.endChar,
      pageIndex: row.pageIndex,
      text: row.anchorText,
      prefix: row.anchorPrefix,
      suffix: row.anchorSuffix,
      orphaned: row.orphaned,
    ),
    style: _enumByName(
      HighlightStyle.values,
      row.style,
      HighlightStyle.highlight,
    ),
    colorValue: row.colorValue,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );

  T _enumByName<T extends Enum>(List<T> values, String name, T fallback) =>
      values.asNameMap()[name] ?? fallback;
}
