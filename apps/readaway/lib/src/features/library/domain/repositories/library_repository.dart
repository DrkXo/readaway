import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entity/reading_status.dart';
import '../entity/recent_document.dart';

/// Contract for library operations, document persistence, and file imports.
abstract interface class LibraryRepository {
  /// Fetches all documents, sorted by most recently opened.
  TaskEither<Failure, List<RecentDocument>> getRecentDocuments();

  /// Adds or updates a document in library history.
  TaskEither<Failure, Unit> saveRecentDocument(RecentDocument document);

  /// Removes a document from the library.
  TaskEither<Failure, Unit> removeRecentDocument(String path);

  /// Removes multiple documents in batch.
  TaskEither<Failure, Unit> removeMultipleDocuments(List<String> paths);

  /// Prompts the user to pick one or more document files from device storage
  /// and saves them into the library.
  /// Returns an empty list if the user cancelled the dialog.
  TaskEither<Failure, List<RecentDocument>> pickAndAddDocuments();

  /// Prompts the user to pick a document file from the device storage.
  /// Returns `None` if the user cancelled the dialog.
  TaskEither<Failure, Option<RecentDocument>> pickDocument();

  /// Prompts the user to pick a document file from storage without saving to the library.
  /// Returns `None` if the user cancelled the dialog.
  TaskEither<Failure, Option<RecentDocument>> pickDocumentWithoutSaving();

  /// Retrieves a cached cover thumbnail path or parses page 0 and caches it.
  TaskEither<Failure, Option<String>> getCoverArtPath(RecentDocument document);

  /// Toggles favorite status for a document.
  TaskEither<Failure, RecentDocument> toggleFavorite(String path);

  /// Updates reading status for a document.
  TaskEither<Failure, RecentDocument> updateReadingStatus(
    String path,
    ReadingStatus status,
  );
}
