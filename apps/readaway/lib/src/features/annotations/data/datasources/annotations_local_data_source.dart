import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/storage/hive/app_storage_service.dart';
import '../../domain/entity/document_notes.dart';

/// Reads and writes [DocumentNotes] records in the annotations box.
///
/// One record per document path: a document's notes are loaded with a single
/// lookup and written back with a single `put`, so a change can never leave a
/// document half-updated.
///
/// [read] and [readAll] are synchronous because Hive reads are synchronous;
/// wrapping them in a `Future` would only hide that.
@lazySingleton
class AnnotationsLocalDataSource {
  final AppStorageService _storage;

  AnnotationsLocalDataSource(this._storage);

  Box<DocumentNotes> get _box => _storage.annotationsBox;

  /// The stored notes for [documentPath], or null when it has none.
  DocumentNotes? read(String documentPath) => _box.get(documentPath);

  /// Every stored record.
  List<DocumentNotes> readAll() => _box.values.toList(growable: false);

  /// Inserts or replaces the record for its document.
  Future<void> write(DocumentNotes document) =>
      _box.put(document.documentPath, document);

  /// Removes the record for [documentPath]. A no-op when absent.
  Future<void> remove(String documentPath) => _box.delete(documentPath);
}
