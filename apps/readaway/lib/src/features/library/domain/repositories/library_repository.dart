import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entity/recent_document.dart';

/// Contract for library operations, document persistence, and file imports.
abstract interface class LibraryRepository {
  /// Fetches all recently opened documents, sorted by most recently opened.
  TaskEither<Failure, List<RecentDocument>> getRecentDocuments();

  /// Adds or updates a document in recent history.
  TaskEither<Failure, Unit> saveRecentDocument(RecentDocument document);

  /// Removes a document from recent history.
  TaskEither<Failure, Unit> removeRecentDocument(String path);

  /// Prompts the user to pick a document file from the device storage.
  /// Returns `None` if the user cancelled the dialog.
  TaskEither<Failure, Option<RecentDocument>> pickDocument();

  /// Retrieves a cached cover thumbnail path or parses page 0 and caches it.
  /// Returns `None` if the cover could not be extracted.
  TaskEither<Failure, Option<String>> getCoverArtPath(RecentDocument document);
}
