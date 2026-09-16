import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'pagination_state.g.dart';

/// Snapshot of the pagination engine state at a point in time.
@CopyWith()
class PaginationState extends Equatable {
  final int chapterIndex;
  final int pageInChapter;
  final int totalPagesInChapter;
  final int globalPage;
  final int totalPages;
  final double viewportHeight;
  final Map<int, double> chapterHeights;
  final Map<int, int> chapterPageCounts;

  const PaginationState({
    this.chapterIndex = 0,
    this.pageInChapter = 0,
    this.totalPagesInChapter = 1,
    this.globalPage = 0,
    this.totalPages = 0,
    this.viewportHeight = 0.0,
    this.chapterHeights = const {},
    this.chapterPageCounts = const {},
  });

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
    chapterIndex,
    pageInChapter,
    totalPagesInChapter,
    globalPage,
    totalPages,
  ];
}
