/// Detected character encoding details.
class DetectedEncoding {
  final String name;
  final double confidence;
  final bool hasBom;

  const DetectedEncoding({
    required this.name,
    required this.confidence,
    required this.hasBom,
  });

  @override
  String toString() => 'DetectedEncoding($name, confidence: $confidence, hasBom: $hasBom)';
}

/// Metadata extracted from a plain-text document.
class TxtMetadata {
  final String title;
  final String? author;
  final String encoding;
  final String? language;

  const TxtMetadata({
    required this.title,
    this.author,
    required this.encoding,
    this.language,
  });

  @override
  String toString() => 'TxtMetadata(title: $title, author: $author, encoding: $encoding)';
}

/// A segmented chapter extracted from a plain-text document.
class TxtChapter {
  final int index;
  final String title;
  final String contentHtml;
  final bool isVolume;
  final bool detected;

  const TxtChapter({
    required this.index,
    required this.title,
    required this.contentHtml,
    required this.isVolume,
    required this.detected,
  });

  @override
  String toString() => 'TxtChapter($index: $title, isVolume: $isVolume)';
}
