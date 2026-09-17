part of 'models.dart';

/// Detected character encoding details.
@freezed
sealed class DetectedEncoding with _$DetectedEncoding {
  const factory DetectedEncoding({
    required String name,
    required double confidence,
    required bool hasBom,
  }) = _DetectedEncoding;
}

/// Metadata extracted from a plain-text document.
@freezed
sealed class TxtMetadata with _$TxtMetadata {
  const factory TxtMetadata({
    required String title,
    String? author,
    required String encoding,
    String? language,
  }) = _TxtMetadata;
}

/// A segmented chapter extracted from a plain-text document.
@freezed
sealed class TxtChapter with _$TxtChapter {
  const factory TxtChapter({
    required int index,
    required String title,
    required String contentHtml,
    required bool isVolume,
    required bool detected,
  }) = _TxtChapter;
}
