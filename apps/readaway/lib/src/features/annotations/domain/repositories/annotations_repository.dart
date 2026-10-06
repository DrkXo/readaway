import '../../../../core/result/result.dart';
import '../entity/document_notes.dart';

/// Contract for reading and writing a document's bookmarks, highlights and
/// notes.
///
/// Records are addressed by document path and stored one record per document,
/// so a mutation rewrites that document's whole note list atomically.
abstract interface class AnnotationsRepository {
  /// The stored notes for [documentPath].
  ///
  /// Returns an empty record (correct [documentPath], no notes) when the
  /// document has none yet, so callers never branch on null.
  Future<Result<DocumentNotes>> getForDocument(String documentPath);

  /// Persists the full note list for [document], stamping the schema version
  /// and the modified time.
  Future<Result<DocumentNotes>> save(DocumentNotes document);

  /// Drops every note for [documentPath].
  ///
  /// Used when the document itself leaves the library, so its annotations do
  /// not outlive it.
  Future<Result<void>> purgeForDocument(String documentPath);
}
