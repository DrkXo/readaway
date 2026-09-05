import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/document_cover_service.dart';
import '../../../../core/services/mupdf_service.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/file_picker_data_source.dart';
import '../datasources/library_local_data_source.dart';

@LazySingleton(as: LibraryRepository)
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryLocalDataSource _localDataSource;
  final FilePickerDataSource _filePickerDataSource;
  final DocumentCoverService _coverService;
  final MuPdfService _muPdfService;

  LibraryRepositoryImpl(
    this._localDataSource,
    this._filePickerDataSource,
    this._coverService,
    this._muPdfService,
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
  TaskEither<Failure, Option<RecentDocument>> pickDocument() {
    return TaskEither.tryCatch(
      () async {
        final doc = await _filePickerDataSource.pickDocumentFile();
        if (doc == null) return none();

        String title = doc.title;
        String? author;
        int pageCount = 0;

        try {
          await _muPdfService.openDocument(doc.path);
          final metaTitle = await _muPdfService.getMetaData('info:Title');
          if (metaTitle != null && metaTitle.trim().isNotEmpty) {
            title = metaTitle.trim();
          }
          final metaAuthor = await _muPdfService.getMetaData('info:Author');
          if (metaAuthor != null && metaAuthor.trim().isNotEmpty) {
            author = metaAuthor.trim();
          }
          pageCount = await _muPdfService.getPageCount();
        } catch (_) {
          // Non-critical if metadata extraction fails for picked file
        }

        String? coverPath;
        try {
          final coverUri = await _coverService.getCoverArtUri(
            filePath: doc.path,
            fileName: doc.fileName,
            pageCount: pageCount > 0 ? pageCount : 1,
          );
          if (coverUri != null && coverUri.isScheme('file')) {
            coverPath = coverUri.toFilePath();
          }
        } catch (_) {
          // Non-critical if cover extraction fails
        }

        final enrichedDoc = doc.copyWith(
          title: title,
          author: author,
          pageCount: pageCount,
          coverPath: coverPath,
        );

        await _localDataSource.saveRecentDocument(enrichedDoc);
        return some(enrichedDoc);
      },
      (error, stack) => DocumentNotFoundFailure(
        'Picker error: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Option<String>> getCoverArtPath(RecentDocument document) {
    return TaskEither.tryCatch(
      () async {
        if (document.coverPath != null &&
            await File(document.coverPath!).exists()) {
          return some(document.coverPath!);
        }

        final coverUri = await _coverService.getCoverArtUri(
          filePath: document.path,
          fileName: document.fileName,
          pageCount: document.pageCount > 0 ? document.pageCount : 1,
        );

        if (coverUri != null && coverUri.isScheme('file')) {
          final newPath = coverUri.toFilePath();
          final updatedDoc = document.copyWith(coverPath: newPath);
          await _localDataSource.saveRecentDocument(updatedDoc);
          return some(newPath);
        }

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
