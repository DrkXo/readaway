import 'dart:math' as math;

import 'package:rxdart/rxdart.dart';

import '../models/models.dart';
import 'page_slicer.dart';

/// Reactive pagination coordinator for reflowable documents.
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

  ValueStream<PaginationState> get state => _stateSubject.stream;
  PaginationState get currentState => _stateSubject.value;
  int get chapterCount => _chapterCount;
  ReadingAnchor get currentAnchor => _currentAnchor;

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

  void setCurrentGlobalPage(int globalPage) {
    final coordinate = coordinateFromGlobalPage(globalPage);
    _currentAnchor = createAnchor(coordinate);
    _emit();
  }

  void setCurrentAnchor(ReadingAnchor anchor) {
    _currentAnchor = anchor;
    _emit();
  }

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
    final lastChapter = math.max(0, _chapterCount - 1);
    final lastPages = _chapterPageCounts[lastChapter] ?? 1;
    return PageCoordinate(
      chapterIndex: lastChapter,
      pageInChapter: lastPages - 1,
      totalPagesInChapter: lastPages,
      globalPage: math.max(0, _totalPages - 1),
    );
  }

  int globalPageFromCoordinate(PageCoordinate coordinate) {
    var global = 0;
    for (var chapter = 0; chapter < coordinate.chapterIndex; chapter++) {
      final pages = _chapterPageCounts[chapter] ?? 1;
      global += pages;
    }
    return global + coordinate.pageInChapter;
  }

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

  List<double> getChapterPageOffsets(int chapterIndex) {
    final cached = _chapterOffsets[chapterIndex];
    if (cached != null) return cached;
    return const [0.0];
  }

  ReadingAnchor createAnchor(PageCoordinate coordinate) => ReadingAnchor(
    chapterIndex: coordinate.chapterIndex,
    progressionInChapter: coordinate.progressionInChapter,
  );

  double? offsetForAnchor(ReadingAnchor anchor) {
    final chapter = anchor.chapterIndex.clamp(
      0,
      math.max(0, _chapterCount - 1),
    );
    final height = _chapterHeights[chapter];
    if (height == null) return null;
    var offset = 0.0;
    for (var i = 0; i < chapter; i++) {
      offset += _chapterHeights[i] ?? 0.0;
    }
    return offset + anchor.progressionInChapter * height;
  }

  ReadingAnchor anchorForOffset(int chapterIndex, double offsetInChapter) {
    final chapter = chapterIndex
        .clamp(0, math.max(0, _chapterCount - 1))
        .toInt();
    final height = _chapterHeights[chapter];
    final progression = (height == null || height <= 0)
        ? 0.0
        : (offsetInChapter / height).clamp(0.0, 1.0);
    return ReadingAnchor(
      chapterIndex: chapter,
      progressionInChapter: progression,
    );
  }

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

  void dispose() {
    _chapterHeights.clear();
    _chapterPageCounts.clear();
    _chapterOffsets.clear();
    _chapterLineBounds.clear();
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
