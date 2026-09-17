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
  }

  Future<void> removeMultipleDocuments(List<String> paths) async {
    await _storage.libraryBox.deleteAll(paths);
  }
}
