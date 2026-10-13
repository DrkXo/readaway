import 'package:injectable/injectable.dart';

import '../../../../core/services/storage/drift/daos/annotations_dao.dart';
import '../../domain/entity/document_notes.dart';

/// Reads and writes [DocumentNotes] records through [AnnotationsDao].
///
/// [read] and [readAll] are asynchronous because the database is; callers that
/// used the old synchronous Hive reads already await them.
@lazySingleton
class AnnotationsLocalDataSource {
  final AnnotationsDao _notes;

  AnnotationsLocalDataSource(this._notes);

  /// The stored notes for [documentPath], or null when it has none.
  Future<DocumentNotes?> read(String documentPath) =>
      _notes.readForDocument(documentPath);

  /// Every stored record.
  Future<List<DocumentNotes>> readAll() => _notes.readAll();

  /// Inserts or replaces the record for its document.
  Future<void> write(DocumentNotes document) => _notes.write(document);

  /// Removes the record for [documentPath]. A no-op when absent.
  Future<void> remove(String documentPath) =>
      _notes.removeForDocument(documentPath);
}
