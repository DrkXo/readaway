import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'page_coordinate.g.dart';

/// The precise location of a page within a reflowable document.
@CopyWith()
class PageCoordinate extends Equatable {
  final int chapterIndex;
  final int pageInChapter;
  final int totalPagesInChapter;
  final int globalPage;

  const PageCoordinate({
    required this.chapterIndex,
    required this.pageInChapter,
    required this.totalPagesInChapter,
    required this.globalPage,
  });

  /// Reading progress within the chapter, in `[0, 1]`.
  double get progressionInChapter => totalPagesInChapter > 1
      ? (pageInChapter / (totalPagesInChapter - 1))
      : 0.0;

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
    chapterIndex,
    pageInChapter,
    totalPagesInChapter,
    globalPage,
  ];
}
