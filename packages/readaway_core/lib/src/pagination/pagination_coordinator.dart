import 'dart:math' as math;

import 'package:rxdart/rxdart.dart';

import '../../readaway_core.dart';

/// Reactive pagination coordinator for reflowable documents.
///
/// Tracks per-chapter content heights, computes page counts via [PageSlicer],
/// and exposes a [ValueStream] of [PaginationState]. Reading position is kept
/// as a stable [ReadingAnchor] (chapter + progression) so it survives reflow
/// changes such as font-size or window resizing.
class PaginationCoordinator {
  final PageSlicer _slicer;
  final BehaviorSubject<PaginationState> _stateSubject;

  int _chapterCount = 0;
  double _viewportHeight = 0.0;
  final Map<int, double> _chapterHeights = {};
  final Map<int, int> _chapterPageCounts = {};
  final Map<int, List<double>> _chapterOffsets = {};
  final Map<int, List<({double top, double bottom})>?> _chapterLineBounds = {};
  ReadingAnchor _currentAnchor = const ReadingAnchor(
    chapterIndex: 0,
    progressionInChapter: 0.0,
  );
  int _totalPages = 0;

  PaginationCoordinator({this._slicer = const PageSlicer()})
    : _stateSubject = BehaviorSubject.seeded(const PaginationState());

  /// Stream of the current pagination state.
  ValueStream<PaginationState> get state => _stateSubject.stream;

  /// Current pagination state.
  PaginationState get currentState => _stateSubject.value;

  /// Number of chapters the coordinator was initialized with.
  int get chapterCount => _chapterCount;

  /// Initializes the coordinator for a document with [chapterCount] chapters.
  void initialize({
    required int chapterCount,
    required double viewportHeight,
    required double contentHeight,
  }) {
    _chapterCount = chapterCount;
    _viewportHeight = viewportHeight;
    _chapterHeights.clear();
    _chapterPageCounts.clear();
    _chapterOffsets.clear();
    _chapterLineBounds.clear();
    _currentAnchor = const ReadingAnchor(
      chapterIndex: 0,
      progressionInChapter: 0.0,
    );
    _totalPages = 0;
    registerChapterHeight(chapterIndex: 0, contentHeight: contentHeight);
  }

  /// Updates the viewport height and recomputes all page counts.
  ///
  /// [contentHeight] is the laid-out height of the current chapter.
  void updateViewport({
    required double viewportHeight,
    required double contentHeight,
  }) {
    _viewportHeight = viewportHeight;
    if (_chapterHeights.isNotEmpty) {
      _chapterHeights[0] = contentHeight;
    }
    _recomputeAll();
    _emit();
  }

  /// Registers the laid-out [contentHeight] of the chapter at [chapterIndex].
  ///
  /// [lineBounds] optionally provides line/block boundaries used to snap page
  /// slices cleanly between lines (see [PageSlicer.computePageOffsets]).
  void registerChapterHeight({
    required int chapterIndex,
    required double contentHeight,
    List<({double top, double bottom})>? lineBounds,
  }) {
    _chapterHeights[chapterIndex] = contentHeight;
    _chapterLineBounds[chapterIndex] = lineBounds;
    _recomputeChapter(chapterIndex);
    _recomputeTotalPages();
    _emit();
  }

  /// Sets the current reading position by global page.
  void setCurrentGlobalPage(int globalPage) {
    final coordinate = coordinateFromGlobalPage(globalPage);
    _currentAnchor = createAnchor(coordinate);
    _emit();
  }

  /// Maps a global page number to its chapter-local [PageCoordinate].
  PageCoordinate coordinateFromGlobalPage(int globalPage) {
    var remaining = globalPage;
    for (var chapter = 0; chapter < _chapterCount; chapter++) {
      final pages = _chapterPageCounts[chapter] ?? 1;
      if (remaining < pages) {
        return PageCoordinate(
          chapterIndex: chapter,
          pageInChapter: remaining,
          totalPagesInChapter: pages,
          globalPage: globalPage,
        );
      }
      remaining -= pages;
    }
    // Clamp to the last page of the document.
    final lastChapter = math.max(0, _chapterCount - 1);
    final lastPages = _chapterPageCounts[lastChapter] ?? 1;
    return PageCoordinate(
      chapterIndex: lastChapter,
      pageInChapter: lastPages - 1,
      totalPagesInChapter: lastPages,
      globalPage: math.max(0, _totalPages - 1),
    );
  }

  /// Maps a chapter-local [PageCoordinate] to a global page number.
  int globalPageFromCoordinate(PageCoordinate coordinate) {
    var global = 0;
    for (var chapter = 0; chapter < coordinate.chapterIndex; chapter++) {
      global += _chapterPageCounts[chapter] ?? 1;
    }
    return global + coordinate.pageInChapter;
  }

  /// Gets the first global page of a given chapter (useful for TOC navigation).
  int getGlobalPageForChapter(int chapterIndex) {
    final clamped = chapterIndex
        .clamp(0, math.max(0, _chapterCount - 1))
        .toInt();
    return globalPageFromCoordinate(
      PageCoordinate(
        chapterIndex: clamped,
        pageInChapter: 0,
        totalPagesInChapter: _chapterPageCounts[clamped] ?? 1,
        globalPage: 0,
      ),
    );
  }

  /// Retrieves the page slice offsets for a specific chapter.
  ///
  /// Falls back to a single page starting at `0.0` when the chapter has not
  /// been measured yet.
  List<double> getChapterPageOffsets(int chapterIndex) {
    final cached = _chapterOffsets[chapterIndex];
    if (cached != null) return cached;
    return const [0.0];
  }

  /// Creates a stable [ReadingAnchor] from a [PageCoordinate].
  ReadingAnchor createAnchor(PageCoordinate coordinate) => ReadingAnchor(
    chapterIndex: coordinate.chapterIndex,
    progressionInChapter: coordinate.progressionInChapter,
  );

  /// Restores a [PageCoordinate] from a stable [ReadingAnchor], clamping to
  /// the current pagination.
  PageCoordinate restoreFromAnchor(ReadingAnchor anchor) {
    final chapter = math.min(
      anchor.chapterIndex,
      math.max(0, _chapterCount - 1),
    );
    final pages = _chapterPageCounts[chapter] ?? 1;
    final page = math.min(
      (anchor.progressionInChapter * (pages - 1)).round(),
      pages - 1,
    );
    return PageCoordinate(
      chapterIndex: chapter,
      pageInChapter: page,
      totalPagesInChapter: pages,
      globalPage: globalPageFromCoordinate(
        PageCoordinate(
          chapterIndex: chapter,
          pageInChapter: page,
          totalPagesInChapter: pages,
          globalPage: 0,
        ),
      ),
    );
  }

  /// Resets all pagination state.
  void reset() {
    _chapterCount = 0;
    _viewportHeight = 0.0;
    _chapterHeights.clear();
    _chapterPageCounts.clear();
    _chapterOffsets.clear();
    _chapterLineBounds.clear();
    _currentAnchor = const ReadingAnchor(
      chapterIndex: 0,
      progressionInChapter: 0.0,
    );
    _totalPages = 0;
    _emit();
  }

  /// Releases the state stream. The coordinator must not be used afterwards.
  void dispose() {
    _stateSubject.close();
  }

  void _recomputeChapter(int chapterIndex) {
    final height = _chapterHeights[chapterIndex];
    if (height == null) return;
    final offsets = _slicer.computePageOffsets(
      contentHeight: height,
      viewportHeight: _viewportHeight,
      lineBounds: _chapterLineBounds[chapterIndex],
    );
    _chapterOffsets[chapterIndex] = offsets;
    _chapterPageCounts[chapterIndex] = offsets.length;
  }

  void _recomputeAll() {
    for (var chapter = 0; chapter < _chapterCount; chapter++) {
      _recomputeChapter(chapter);
    }
    _recomputeTotalPages();
  }

  void _recomputeTotalPages() {
    var total = 0;
    for (var chapter = 0; chapter < _chapterCount; chapter++) {
      total += _chapterPageCounts[chapter] ?? 1;
    }
    _totalPages = total;
  }

  void _emit() {
    final coordinate = restoreFromAnchor(_currentAnchor);
    _stateSubject.add(
      PaginationState(
        chapterIndex: coordinate.chapterIndex,
        pageInChapter: coordinate.pageInChapter,
        totalPagesInChapter: coordinate.totalPagesInChapter,
        globalPage: coordinate.globalPage,
        totalPages: _totalPages,
        viewportHeight: _viewportHeight,
        chapterHeights: Map.unmodifiable(_chapterHeights),
        chapterPageCounts: Map.unmodifiable(_chapterPageCounts),
      ),
    );
  }
}
