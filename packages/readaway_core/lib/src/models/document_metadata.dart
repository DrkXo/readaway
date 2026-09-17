part of 'models.dart';

/// Bibliographic metadata for a document.
@freezed
sealed class DocumentMetadata with _$DocumentMetadata {
  const factory DocumentMetadata({
    String? title,
    String? author,
    String? creator,
    String? language,
    String? identifier,
    String? publisher,
    String? description,
    String? coverImagePath,
  }) = _DocumentMetadata;

  /// Constructs metadata normalizing `author`/`creator` to be symmetric:
  /// when only one is provided, the other mirrors it.
  factory DocumentMetadata.normalized({
    String? title,
    String? author,
    String? creator,
    String? language,
    String? identifier,
    String? publisher,
    String? description,
    String? coverImagePath,
  }) {
    final resolvedAuthor = author ?? creator;
    final resolvedCreator = creator ?? author;
    return DocumentMetadata(
      title: title,
      author: resolvedAuthor,
      creator: resolvedCreator,
      language: language,
      identifier: identifier,
      publisher: publisher,
      description: description,
      coverImagePath: coverImagePath,
    );
  }
}
