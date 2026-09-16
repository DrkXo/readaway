import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'reading_anchor.g.dart';

/// Stable anchor representing a reading position within a reflowable document.
@CopyWith()
class ReadingAnchor extends Equatable {
  final int chapterIndex;
  final double progressionInChapter;

  const ReadingAnchor({
    required this.chapterIndex,
    required this.progressionInChapter,
  });

  factory ReadingAnchor.fromJson(Map<String, dynamic> json) => ReadingAnchor(
    chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
    progressionInChapter:
        (json['progressionInChapter'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'chapterIndex': chapterIndex,
    'progressionInChapter': progressionInChapter,
  };

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [chapterIndex, progressionInChapter];
}
