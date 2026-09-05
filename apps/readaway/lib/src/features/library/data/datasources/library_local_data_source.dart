import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/services/logging_service.dart';
import '../../../../core/services/storage/hive/app_storage_service.dart';
import '../../domain/entity/recent_document.dart';

@lazySingleton
class LibraryLocalDataSource {
  final AppStorageService _storage;

  static const String _recentDocsKey = 'library_recent_documents';

  LibraryLocalDataSource(this._storage);

  Future<List<RecentDocument>> getRecentDocuments() async {
    final raw = _storage.readAsString(_recentDocsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = <RecentDocument>[];
      for (final item in decoded) {
        try {
          list.add(RecentDocument.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          logger.w('[LibraryLocalDataSource] Skipped invalid entry: $e');
        }
      }
      return list;
    } catch (e) {
      logger.e('[LibraryLocalDataSource] Failed to parse library documents: $e');
      return const [];
    }
  }

  Future<void> saveRecentDocument(RecentDocument document) async {
    final docs = (await getRecentDocuments()).toList();
    final index = docs.indexWhere((doc) => doc.path == document.path);
    if (index != -1) {
      docs[index] = document;
    } else {
      docs.insert(0, document);
    }

    final jsonString = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _storage.writeAsString(_recentDocsKey, jsonString);
  }

  Future<void> saveAllDocuments(List<RecentDocument> documents) async {
    final jsonString = jsonEncode(documents.map((d) => d.toJson()).toList());
    await _storage.writeAsString(_recentDocsKey, jsonString);
  }

  Future<void> removeRecentDocument(String path) async {
    final docs = (await getRecentDocuments()).toList();
    docs.removeWhere((doc) => doc.path == path);

    final jsonString = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _storage.writeAsString(_recentDocsKey, jsonString);
  }

  Future<void> removeMultipleDocuments(List<String> paths) async {
    final docs = (await getRecentDocuments()).toList();
    final pathSet = paths.toSet();
    docs.removeWhere((doc) => pathSet.contains(doc.path));

    final jsonString = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _storage.writeAsString(_recentDocsKey, jsonString);
  }
}
