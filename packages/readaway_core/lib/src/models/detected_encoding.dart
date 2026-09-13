part of 'models.dart';

/// Result of automatic character encoding detection.
@freezed
abstract class DetectedEncoding with _$DetectedEncoding {
  const factory DetectedEncoding({
    /// Canonical encoding name (e.g. 'utf-8', 'utf-16le', 'utf-16be', 'gbk', 'gb18030', 'shift-jis').
    required String name,

    /// Confidence score between 0.0 and 1.0.
    required double confidence,

    /// True if a definitive Byte Order Mark (BOM) was encountered.
    @Default(false) bool hasBom,
  }) = _DetectedEncoding;

  factory DetectedEncoding.fromJson(Map<String, dynamic> json) =>
      _$DetectedEncodingFromJson(json);
}
