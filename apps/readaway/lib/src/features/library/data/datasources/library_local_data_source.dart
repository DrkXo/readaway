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
      return decoded
          .map((item) => RecentDocument.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('[LibraryLocalDataSource] Failed to parse recent documents: $e');
      return const [];
    }
  }

  Future<void> saveRecentDocument(RecentDocument document) async {
    final docs = (await getRecentDocuments()).toList();
    // Remove if already exists so we bump to front
    docs.removeWhere((doc) => doc.path == document.path);
    docs.insert(0, document);

    // Keep at most 50 recent items
    if (docs.length > 50) {
      docs.removeRange(50, docs.length);
    }

    final jsonString = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _storage.writeAsString(_recentDocsKey, jsonString);
  }

  Future<void> removeRecentDocument(String path) async {
    final docs = (await getRecentDocuments()).toList();
    docs.removeWhere((doc) => doc.path == path);

    final jsonString = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _storage.writeAsString(_recentDocsKey, jsonString);
  }
}
