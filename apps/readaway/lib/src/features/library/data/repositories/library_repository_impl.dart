import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/path_service.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/file_picker_data_source.dart';
import '../datasources/library_local_data_source.dart';

@LazySingleton(as: LibraryRepository)
class LibraryRepositoryImpl implements LibraryRepository {
  // ignore: unused_field
  final _log = AppLogger.instance.scope('LibraryRepository');

  final LibraryLocalDataSource _localDataSource;
  final FilePickerDataSource _filePickerDataSource;
  final AppPathService _pathService;

  LibraryRepositoryImpl(
    this._localDataSource,
    this._filePickerDataSource,
    this._pathService,
  );

  @override
  Future<Result<List<RecentDocument>>> getRecentDocuments() {
    return guard(
      () => _localDataSource.getRecentDocuments(),
      onError: (error, stack) => StorageReadFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> saveRecentDocument(RecentDocument document) {
    return guard(
      () async {
        await _localDataSource.saveRecentDocument(document);
      },
      onError: (error, stack) => StorageWriteFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  Future<void> _deleteCoverFile(RecentDocument? doc, String path) async {
    try {
      if (doc?.coverPath != null) {
        final f = File(doc!.coverPath!);
        if (await f.exists()) {
          await f.delete();
        }
      }
      final coverDir = await _pathService.getCoversDirectory();
      final fileHash = md5
          .convert(utf8.encode(path))
          .toString()
          .substring(0, 8);
      final fileName = doc?.fileName ?? p.basename(path);
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final coverFile = File(
        p.join(coverDir.path, 'cover_${safeName}_$fileHash.jpg'),
      );
      if (await coverFile.exists()) {
        await coverFile.delete();
      }
    } catch (_) {}
  }

  @override
  Future<Result<void>> removeRecentDocument(String path) {
    return guard(
      () async {
        final docs = await _localDataSource.getRecentDocuments();
        final doc = docs.where((d) => d.path == path).firstOrNull;
        await _deleteCoverFile(doc, path);
        await _localDataSource.removeRecentDocument(path);
      },
      onError: (error, stack) => StorageWriteFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> removeMultipleDocuments(List<String> paths) {
    return guard(
      () async {
        final docs = await _localDataSource.getRecentDocuments();
        final docMap = {for (final d in docs) d.path: d};
        for (final path in paths) {
          await _deleteCoverFile(docMap[path], path);
        }
        await _localDataSource.removeMultipleDocuments(paths);
      },
      onError: (error, stack) => StorageWriteFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<List<RecentDocument>>> pickAndAddDocuments() {
    return guard(
      () async {
        final pickedDocs = await _filePickerDataSource.pickDocumentFiles();
        if (pickedDocs.isEmpty) return <RecentDocument>[];

        final enrichedList = <RecentDocument>[];
        for (final doc in pickedDocs) {
          final enriched = await _enrichAndSave(doc);
          enrichedList.add(enriched);
        }
        return enrichedList;
      },
      onError: (error, stack) => DocumentNotFoundFailure(
        'Picker error: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<RecentDocument?>> pickDocument() async {
    final result = await pickAndAddDocuments();
    return switch (result) {
      Success(:final data) => Success(data.isEmpty ? null : data.first),
      Failed(:final error) => Failed(error),
    };
  }

  @override
  Future<Result<RecentDocument?>> pickDocumentWithoutSaving() {
    return guard(
      () async {
        final doc = await _filePickerDataSource.pickDocumentFile();
        return doc;
      },
      onError: (error, stack) => DocumentNotFoundFailure(
        'Picker error: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  Future<RecentDocument> _enrichAndSave(RecentDocument doc) async {
    String title = doc.title;
    String? author;
    int pageCount = 0;
    Uint8List? coverBytes;

    try {
      final session = await IsolateDocumentSession.open(doc.path);
      final metaTitle = session.title;
      if (metaTitle != null && metaTitle.trim().isNotEmpty) {
        title = metaTitle.trim();
      }
      final metaAuthor = session.metadata?.creator;
      if (metaAuthor != null && metaAuthor.trim().isNotEmpty) {
        author = metaAuthor.trim();
      }
      pageCount = session.isReflowable
          ? session.sectionCount
          : session.pageCount;
      final coverImgPath = session.coverImagePath;
      if (coverImgPath != null) {
        coverBytes = await session.loadAsset(coverImgPath);
      }
      await session.dispose();
    } catch (_) {
      // Non-critical if metadata extraction fails for picked file
    }

    String? coverPath;
    if (coverBytes != null && coverBytes.isNotEmpty) {
      try {
        final coverDir = await _pathService.getCoversDirectory();
        final fileHash = md5
            .convert(utf8.encode(doc.path))
            .toString()
            .substring(0, 8);
        final safeName = doc.fileName.replaceAll(
          RegExp(r'[^a-zA-Z0-9_-]'),
          '_',
        );
        final coverFile = File(
          p.join(coverDir.path, 'cover_${safeName}_$fileHash.jpg'),
        );
        if (!await coverFile.exists()) {
          await coverFile.writeAsBytes(coverBytes, flush: true);
        }
        coverPath = coverFile.path;
      } catch (_) {
        // Non-critical if saving cover file fails
      }
    }

    final enrichedDoc = doc.copyWith(
      title: title,
      author: author,
      pageCount: pageCount,
      coverPath: coverPath,
    );

    await _localDataSource.saveRecentDocument(enrichedDoc);
    return enrichedDoc;
  }

  @override
  Future<Result<String?>> getCoverArtPath(RecentDocument document) {
    return guard(
      () async {
        if (document.coverPath != null &&
            await File(document.coverPath!).exists()) {
          return document.coverPath;
        }

        try {
          final coverDir = await _pathService.getCoversDirectory();
          final fileHash = md5
              .convert(utf8.encode(document.path))
              .toString()
              .substring(0, 8);
          final safeName = document.fileName.replaceAll(
            RegExp(r'[^a-zA-Z0-9_-]'),
            '_',
          );
          final coverFile = File(
            p.join(coverDir.path, 'cover_${safeName}_$fileHash.jpg'),
          );

          if (await coverFile.exists()) {
            final updatedDoc = document.copyWith(coverPath: coverFile.path);
            await _localDataSource.saveRecentDocument(updatedDoc);
            return coverFile.path;
          }

          final session = await IsolateDocumentSession.open(document.path);
          final coverImgPath = session.coverImagePath;
          if (coverImgPath != null) {
            final bytes = await session.loadAsset(coverImgPath);
            if (bytes != null && bytes.isNotEmpty) {
              await coverFile.writeAsBytes(bytes, flush: true);
              final updatedDoc = document.copyWith(coverPath: coverFile.path);
              await _localDataSource.saveRecentDocument(updatedDoc);
              await session.dispose();
              return coverFile.path;
            }
          }
          await session.dispose();
        } catch (_) {}

        return null;
      },
      onError: (error, stack) => UnexpectedFailure(
        'Failed to extract cover for ${document.fileName}: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<RecentDocument>> toggleFavorite(String path) {
    return guard(
      () async {
        final docs = await _localDataSource.getRecentDocuments();
        final doc = docs.firstWhere((d) => d.path == path);
        final updated = doc.copyWith(isFavorite: !doc.isFavorite);
        await _localDataSource.saveRecentDocument(updated);
        return updated;
      },
      onError: (error, stack) => StorageWriteFailure(
        'Failed to toggle favorite: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<RecentDocument>> updateReadingStatus(
    String path,
    ReadingStatus status,
  ) {
    return guard(
      () async {
        final docs = await _localDataSource.getRecentDocuments();
        final doc = docs.firstWhere((d) => d.path == path);
        final RecentDocument updated;
        switch (status) {
          case ReadingStatus.unread:
            updated = doc.copyWith(
              readingStatus: ReadingStatus.unread,
              lastReadPage: 0,
              lastReadChapter: 0,
              lastReadProgression: 0.0,
            );
          case ReadingStatus.finished:
            final lastPage = doc.pageCount > 0 ? doc.pageCount - 1 : 0;
            updated = doc.copyWith(
              readingStatus: ReadingStatus.finished,
              lastReadPage: lastPage,
              lastReadChapter: lastPage,
              lastReadProgression: 1.0,
            );
          case ReadingStatus.reading:
            updated = doc.copyWith(
              readingStatus: ReadingStatus.reading,
            );
          case ReadingStatus.abandoned:
            updated = doc.copyWith(
              readingStatus: ReadingStatus.abandoned,
            );
        }
        await _localDataSource.saveRecentDocument(updated);
        return updated;
      },
      onError: (error, stack) => StorageWriteFailure(
        'Failed to update reading status: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<RecentDocument>> resetReadingProgress(String path) {
    return updateReadingStatus(path, ReadingStatus.unread);
  }
}
