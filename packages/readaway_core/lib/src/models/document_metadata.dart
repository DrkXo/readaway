part of 'models.dart';

/// Bibliographic metadata extracted from a document (e.g. EPUB OPF `<metadata>`).
@freezed
abstract class DocumentMetadata with _$DocumentMetadata {
  const factory DocumentMetadata({
    /// Document title.
    String? title,

    /// Primary author/creator.
    String? creator,

    /// Language code (e.g. `en`, `fr`).
    String? language,

    /// Unique document identifier.
    String? identifier,

    /// Publisher name.
    String? publisher,

    /// Short description / synopsis.
    String? description,

    /// Subject or category.
    String? subject,

    /// Last modification timestamp, if known.
    DateTime? modified,
  }) = _DocumentMetadata;

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) =>
      _$DocumentMetadataFromJson(json);
}
