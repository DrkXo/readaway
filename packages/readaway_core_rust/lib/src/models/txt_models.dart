import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'txt_models.g.dart';

/// Detected character encoding details.
@CopyWith()
class DetectedEncoding extends Equatable {
  final String name;
  final double confidence;
  final bool hasBom;

  const DetectedEncoding({
    required this.name,
    required this.confidence,
    required this.hasBom,
  });

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [name, confidence, hasBom];
}

/// Metadata extracted from a plain-text document.
@CopyWith()
class TxtMetadata extends Equatable {
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
  bool get stringify => true;

  @override
  List<Object?> get props => [title, author, encoding, language];
}

/// A segmented chapter extracted from a plain-text document.
@CopyWith()
class TxtChapter extends Equatable {
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
  bool get stringify => true;

  @override
  List<Object?> get props => [index, title, contentHtml, isVolume, detected];
}
