part of 'models.dart';

/// Metadata extracted from a plain text document's filename and header.
@freezed
abstract class TxtMetadata with _$TxtMetadata {
  const factory TxtMetadata({
    /// Extracted or fallback title of the document.
    required String title,

    /// Extracted author name if detected, or null.
    String? author,

    /// Detected or provided BCP-47 language tag.
    String? language,

    /// Character encoding detected or used (e.g. 'utf-8', 'gbk', 'shift-jis').
    required String encoding,

    /// Stable content identifier.
    String? identifier,
  }) = _TxtMetadata;

  factory TxtMetadata.fromJson(Map<String, dynamic> json) =>
      _$TxtMetadataFromJson(json);
}
