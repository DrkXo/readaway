import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/path_service.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/file_picker_data_source.dart';
import '../datasources/library_local_data_source.dart';

@LazySingleton(as: LibraryRepository)
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryLocalDataSource _localDataSource;
  final FilePickerDataSource _filePickerDataSource;
  final AppPathService _pathService;

  LibraryRepositoryImpl(
    this._localDataSource,
    this._filePickerDataSource,
    this._pathService,
  );

  @override
  TaskEither<Failure, List<RecentDocument>> getRecentDocuments() {
    return TaskEither.tryCatch(
      () => _localDataSource.getRecentDocuments(),
      (error, stack) => StorageReadFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> saveRecentDocument(RecentDocument document) {
    return TaskEither.tryCatch(
      () async {
        await _localDataSource.saveRecentDocument(document);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> removeRecentDocument(String path) {
    return TaskEither.tryCatch(
      () async {
        await _localDataSource.removeRecentDocument(path);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> removeMultipleDocuments(List<String> paths) {
    return TaskEither.tryCatch(
      () async {
        await _localDataSource.removeMultipleDocuments(paths);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        'library_recent_documents',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, List<RecentDocument>> pickAndAddDocuments() {
    return TaskEither.tryCatch(
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
      (error, stack) => DocumentNotFoundFailure(
        'Picker error: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Option<RecentDocument>> pickDocument() {
    return pickAndAddDocuments().map(
      (docs) => docs.isEmpty ? none() : some(docs.first),
    );
  }

  @override
  TaskEither<Failure, Option<RecentDocument>> pickDocumentWithoutSaving() {
    return TaskEither.tryCatch(
      () async {
        final doc = await _filePickerDataSource.pickDocumentFile();
        if (doc == null) return none();
        return some(doc);
      },
      (error, stack) => DocumentNotFoundFailure(
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
      pageCount = session.sectionCount;
      final coverImgPath = session.coverImagePath;
      if (coverImgPath != null) {
        coverBytes = await session.loadAsset(coverImgPath);
      }
      session.dispose();
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
  TaskEither<Failure, Option<String>> getCoverArtPath(RecentDocument document) {
    return TaskEither.tryCatch(
      () async {
        if (document.coverPath != null &&
            await File(document.coverPath!).exists()) {
          return some(document.coverPath!);
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
            return some(coverFile.path);
          }

          final session = await IsolateDocumentSession.open(document.path);
          final coverImgPath = session.coverImagePath;
          if (coverImgPath != null) {
            final bytes = await session.loadAsset(coverImgPath);
            if (bytes != null && bytes.isNotEmpty) {
              await coverFile.writeAsBytes(bytes, flush: true);
              final updatedDoc = document.copyWith(coverPath: coverFile.path);
              await _localDataSource.saveRecentDocument(updatedDoc);
              session.dispose();
              return some(coverFile.path);
            }
          }
          session.dispose();
        } catch (_) {}

        return none();
      },
      (error, stack) => UnexpectedFailure(
        'Failed to extract cover for ${document.fileName}: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, RecentDocument> toggleFavorite(String path) {
    return TaskEither.tryCatch(
      () async {
        final docs = await _localDataSource.getRecentDocuments();
        final doc = docs.firstWhere((d) => d.path == path);
        final updated = doc.copyWith(isFavorite: !doc.isFavorite);
        await _localDataSource.saveRecentDocument(updated);
        return updated;
      },
      (error, stack) => StorageWriteFailure(
        'Failed to toggle favorite: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, RecentDocument> updateReadingStatus(
    String path,
    ReadingStatus status,
  ) {
    return TaskEither.tryCatch(
      () async {
        final docs = await _localDataSource.getRecentDocuments();
        final doc = docs.firstWhere((d) => d.path == path);
        final updated = doc.copyWith(readingStatus: status);
        await _localDataSource.saveRecentDocument(updated);
        return updated;
      },
      (error, stack) => StorageWriteFailure(
        'Failed to update reading status: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
