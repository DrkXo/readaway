import 'package:injectable/injectable.dart';

import '../../../../core/services/storage/drift/daos/documents_dao.dart';
import '../../../../core/services/storage/drift/daos/reader_preferences_dao.dart';
import '../../domain/entity/recent_document.dart';

@lazySingleton
class LibraryLocalDataSource {
  final DocumentsDao _documents;
  final ReaderPreferencesDao _readerPreferences;

  LibraryLocalDataSource(this._documents, this._readerPreferences);

  Future<List<RecentDocument>> getRecentDocuments() =>
      _documents.getRecentDocuments();

  Stream<List<RecentDocument>> watchRecentDocuments() =>
      _documents.watchRecentDocuments();

  Future<void> saveRecentDocument(RecentDocument document) =>
      _documents.upsertDocument(document);

  Future<void> saveAllDocuments(List<RecentDocument> documents) =>
      _documents.upsertDocuments(documents);

  Future<void> removeRecentDocument(String path) async {
    await _documents.removeDocument(path);
    // Legacy path-keyed reader preferences are removed with the document.
    // Content-keyed preferences are intentionally retained so settings follow
    // an identical re-import of the same bytes.
    await _readerPreferences.deletePathKeyed(path);
  }

  Future<void> removeMultipleDocuments(List<String> paths) async {
    await _documents.removeDocuments(paths);
    await _readerPreferences.deletePathKeyedMany(paths);
  }
}
