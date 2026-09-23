import '../../../../core/result/result.dart';
import '../entity/reading_status.dart';
import '../entity/recent_document.dart';

/// Contract for library operations, document persistence, and file imports.
abstract interface class LibraryRepository {
  /// Fetches all documents, sorted by most recently opened.
  Future<Result<List<RecentDocument>>> getRecentDocuments();

  /// Adds or updates a document in library history.
  Future<Result<void>> saveRecentDocument(RecentDocument document);

  /// Removes a document from the library.
  Future<Result<void>> removeRecentDocument(String path);

  /// Removes multiple documents in batch.
  Future<Result<void>> removeMultipleDocuments(List<String> paths);

  /// Prompts the user to pick one or more document files from device storage
  /// and saves them into the library.
  /// Returns an empty list if the user cancelled the dialog.
  Future<Result<List<RecentDocument>>> pickAndAddDocuments();

  /// Prompts the user to pick a document file from the device storage.
  /// Returns `null` if the user cancelled the dialog.
  Future<Result<RecentDocument?>> pickDocument();

  /// Prompts the user to pick a document file from storage without saving to the library.
  /// Returns `null` if the user cancelled the dialog.
  Future<Result<RecentDocument?>> pickDocumentWithoutSaving();

  /// Retrieves a cached cover thumbnail path or parses page 0 and caches it.
  Future<Result<String?>> getCoverArtPath(RecentDocument document);

  /// Toggles favorite status for a document.
  Future<Result<RecentDocument>> toggleFavorite(String path);

  /// Updates reading status for a document.
  Future<Result<RecentDocument>> updateReadingStatus(
    String path,
    ReadingStatus status,
  );

  /// Resets reading progress for a document back to the beginning (page 0, unread).
  Future<Result<RecentDocument>> resetReadingProgress(String path);
}
