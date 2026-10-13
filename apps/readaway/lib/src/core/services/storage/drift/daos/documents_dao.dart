import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../../features/library/domain/entity/reading_status.dart';
import '../../../../../features/library/domain/entity/recent_document.dart';
import '../app_database.dart';
import '../tables/documents_table.dart';

part 'documents_dao.g.dart';

/// Persists library documents and their tags.
///
/// Documents are keyed by path. Tags are normalized into [DocumentTags] so
/// future tag filtering is an indexed lookup; the DAO owns the cascade (delete
/// child rows before the parent) because foreign-key cascades cannot run on the
/// web build.
@DriftAccessor(tables: [Documents, DocumentTags])
@lazySingleton
class DocumentsDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(super.db);

  /// All documents, most recently opened first (mirrors the Hive behaviour).
  Future<List<RecentDocument>> getRecentDocuments() async {
    return _mapJoin(await _documentsWithTags().get());
  }

  /// Emits the current library immediately, then on any change.
  Stream<List<RecentDocument>> watchRecentDocuments() {
    return _documentsWithTags().watch().map(_mapJoin);
  }

  /// Inserts or fully replaces [document] and its tags in one transaction.
  Future<void> upsertDocument(RecentDocument document) {
    return transaction(() async {
      await into(documents).insertOnConflictUpdate(_toRow(document));
      await _replaceTags(document.path, document.tags);
    });
  }

  /// Batch-inserts or replaces a list of documents in one transaction.
  Future<void> upsertDocuments(List<RecentDocument> documentsToSave) {
    return transaction(() async {
      for (final doc in documentsToSave) {
        await into(documents).insertOnConflictUpdate(_toRow(doc));
        await _replaceTags(doc.path, doc.tags);
      }
    });
  }

  /// Removes [path] and its tags.
  Future<void> removeDocument(String path) {
    return transaction(() async {
      await (delete(
        documentTags,
      )..where((t) => t.documentPath.equals(path))).go();
      await (delete(documents)..where((d) => d.path.equals(path))).go();
    });
  }

  /// Removes every given path and its tags.
  Future<void> removeDocuments(List<String> paths) {
    if (paths.isEmpty) return Future.value();
    return transaction(() async {
      await (delete(
        documentTags,
      )..where((t) => t.documentPath.isIn(paths))).go();
      await (delete(documents)..where((d) => d.path.isIn(paths))).go();
    });
  }

  JoinedSelectStatement _documentsWithTags() {
    return select(documents).join([
      leftOuterJoin(
        documentTags,
        documentTags.documentPath.equalsExp(documents.path),
      ),
    ])..orderBy([OrderingTerm.desc(documents.lastOpened)]);
  }

  Future<void> _replaceTags(String path, List<String> tags) async {
    await (delete(
      documentTags,
    )..where((t) => t.documentPath.equals(path))).go();
    for (final tag in tags) {
      await into(documentTags).insert(
        DocumentTagRow(documentPath: path, tag: tag),
      );
    }
  }

  DocumentRow _toRow(RecentDocument doc) => DocumentRow(
    path: doc.path,
    fileName: doc.fileName,
    title: doc.title,
    author: doc.author,
    dateAdded: doc.dateAdded,
    lastOpened: doc.lastOpened,
    fileSize: doc.fileSize,
    format: doc.format,
    lastReadPage: doc.lastReadPage,
    pageCount: doc.pageCount,
    lastReadChapter: doc.lastReadChapter,
    lastReadProgression: doc.lastReadProgression,
    readingStatus: doc.readingStatus.name,
    isFavorite: doc.isFavorite,
    coverPath: doc.coverPath,
  );

  List<RecentDocument> _mapJoin(List<TypedResult> rows) {
    final byPath = <String, ({DocumentRow row, List<String> tags})>{};
    final order = <String>[];
    for (final result in rows) {
      final doc = result.readTable(documents);
      final tag = result.readTableOrNull(documentTags)?.tag;
      final current = byPath[doc.path];
      if (current == null) {
        byPath[doc.path] = (
          row: doc,
          tags: tag == null ? <String>[] : <String>[tag],
        );
        order.add(doc.path);
      } else if (tag != null) {
        current.tags.add(tag);
      }
    }
    return [
      for (final path in order)
        _mapDocument(byPath[path]!.row, byPath[path]!.tags),
    ];
  }

  RecentDocument _mapDocument(DocumentRow row, List<String> tags) =>
      RecentDocument(
        path: row.path,
        fileName: row.fileName,
        title: row.title,
        author: row.author,
        dateAdded: row.dateAdded,
        lastOpened: row.lastOpened,
        fileSize: row.fileSize,
        format: row.format,
        lastReadPage: row.lastReadPage,
        pageCount: row.pageCount,
        lastReadChapter: row.lastReadChapter,
        lastReadProgression: row.lastReadProgression,
        readingStatus: ReadingStatus.values.firstWhere(
          (s) => s.name == row.readingStatus,
          orElse: () => ReadingStatus.unread,
        ),
        isFavorite: row.isFavorite,
        tags: tags,
        coverPath: row.coverPath,
      );
}
