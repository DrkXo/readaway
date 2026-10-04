import 'package:injectable/injectable.dart';

import '../../../../core/services/storage/hive/app_storage_service.dart';
import '../../domain/entity/recent_document.dart';

@lazySingleton
class LibraryLocalDataSource {
  final AppStorageService _storage;

  LibraryLocalDataSource(this._storage);

  Future<List<RecentDocument>> getRecentDocuments() async {
    final docs = _storage.libraryBox.values.toList();
    docs.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return docs;
  }

  Stream<List<RecentDocument>> watchRecentDocuments() async* {
    yield await getRecentDocuments();
    yield* _storage.libraryBox.watch().asyncMap((_) => getRecentDocuments());
  }

  Future<void> saveRecentDocument(RecentDocument document) async {
    await _storage.libraryBox.put(document.path, document);
  }

  Future<void> saveAllDocuments(List<RecentDocument> documents) async {
    await _storage.libraryBox.putAll({
      for (final doc in documents) doc.path: doc,
    });
  }

  Future<void> removeRecentDocument(String path) async {
    await _storage.libraryBox.delete(path);
    // Legacy path-keyed reader preferences are removed with the document.
    // Content-keyed preferences are intentionally retained so settings follow
    // an identical re-import of the same bytes.
    await _storage.readerBox.delete('reader_doc_$path');
  }

  Future<void> removeMultipleDocuments(List<String> paths) async {
    await _storage.libraryBox.deleteAll(paths);
    await _storage.readerBox.deleteAll(paths.map((p) => 'reader_doc_$p'));
  }
}
