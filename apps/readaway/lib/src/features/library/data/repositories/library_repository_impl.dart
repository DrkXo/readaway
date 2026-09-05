import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/document_cover_service.dart';
import '../../domain/entity/recent_document.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/file_picker_data_source.dart';
import '../datasources/library_local_data_source.dart';

@LazySingleton(as: LibraryRepository)
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryLocalDataSource _localDataSource;
  final FilePickerDataSource _filePickerDataSource;
  final DocumentCoverService _coverService;

  LibraryRepositoryImpl(
    this._localDataSource,
    this._filePickerDataSource,
    this._coverService,
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
  TaskEither<Failure, Option<RecentDocument>> pickDocument() {
    return TaskEither.tryCatch(
      () async {
        final doc = await _filePickerDataSource.pickDocumentFile();
        if (doc != null) {
          String? coverPath;
          try {
            final coverUri = await _coverService.getCoverArtUri(
              filePath: doc.path,
              fileName: doc.fileName,
              pageCount: 1,
            );
            if (coverUri != null && coverUri.isScheme('file')) {
              coverPath = coverUri.toFilePath();
            }
          } catch (_) {
            // Non-critical if cover extraction fails for picked file
          }

          final docWithCover = doc.copyWith(coverPath: coverPath);
          await _localDataSource.saveRecentDocument(docWithCover);
          return some(docWithCover);
        }
        return none();
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
}
