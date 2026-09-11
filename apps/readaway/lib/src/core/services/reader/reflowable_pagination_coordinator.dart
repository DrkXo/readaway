import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import 'reflowable_document_reader.dart';
import 'reflowable_page_slicer.dart';

/// Represents the precise location within a reflowable document.
@immutable
class PageCoordinate {
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

  double get progressionInChapter => totalPagesInChapter > 1
      ? (pageInChapter / (totalPagesInChapter - 1))
      : 0.0;

  @override
  String toString() =>
      'PageCoordinate(ch: $chapterIndex, p: $pageInChapter/$totalPagesInChapter, global: $globalPage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageCoordinate &&
          chapterIndex == other.chapterIndex &&
          pageInChapter == other.pageInChapter &&
          totalPagesInChapter == other.totalPagesInChapter &&
          globalPage == other.globalPage;

  @override
  int get hashCode =>
      Object.hash(chapterIndex, pageInChapter, totalPagesInChapter, globalPage);
}

/// A stable bookmark/anchor that survives font size, window resize, and reflow changes.
@immutable
class ReadingAnchor {
  final int chapterIndex;
  final double progressionInChapter;

  const ReadingAnchor({
    required this.chapterIndex,
    required this.progressionInChapter,
  });

  @override
  String toString() =>
      'ReadingAnchor(ch: $chapterIndex, prog: ${(progressionInChapter * 100).toStringAsFixed(1)}%)';
}

/// Manages book-wide virtual pagination for reflowable documents.
///
/// Bridges the chapter-based spine of [ReflowableDocumentReader] and the
/// unified, continuous screen-by-screen navigation of [PagedReaderView].
@lazySingleton
class ReflowablePaginationCoordinator extends ChangeNotifier {
  final ReflowablePageSlicer _slicer;
  ReflowableDocumentReader? _reader;

  int _chapterCount = 0;
  Size _viewportSize = Size.zero;
  EdgeInsets _contentMargins = EdgeInsets.zero;

  /// Cache of page offsets for each chapter: `chapterIndex -> [0.0, y1, y2, ...]`.
  final Map<int, List<double>> _chapterOffsets = {};

  /// Cache of total content height for each measured chapter.
  final Map<int, double> _chapterContentHeights = {};

  /// Number of pages per chapter (measured or estimated).
  late List<int> _pagesPerChapter;

  /// Cumulative prefix sums of page counts for fast O(log N) lookup.
  List<int> _prefixSums = [];

  ReflowablePaginationCoordinator({
    this._slicer = const ReflowablePageSlicer(),
  }) : _pagesPerChapter = [];

  int get chapterCount => _chapterCount;
  ReflowableDocumentReader? get reader => _reader;
  int get totalPageCount =>
      _prefixSums.isEmpty ? _chapterCount : _prefixSums.last;
  Size get viewportSize => _viewportSize;

  double get availableHeight =>
      math.max(100.0, _viewportSize.height - _contentMargins.vertical);
  double get availableWidth =>
      math.max(100.0, _viewportSize.width - _contentMargins.horizontal);

  /// Initializes the coordinator for a reflowable document.
  void initialize({
    required int chapterCount,
    required Size viewportSize,
    required EdgeInsets contentMargins,
    ReflowableDocumentReader? reader,
    bool notify = true,
  }) {
    _reader = reader;
    _chapterCount = chapterCount;
    _viewportSize = viewportSize;
    _contentMargins = contentMargins;

    _chapterOffsets.clear();
    _chapterContentHeights.clear();
    _pagesPerChapter = List.filled(_chapterCount, 1);
    _recomputePrefixSums();
    if (notify) notifyListeners();
  }

  /// Updates viewport constraints or margins when device rotates or window resizes.
  ///
  /// Returns a new [globalPage] calculated from [currentAnchor] to preserve reading position.
  int updateViewport({
    required Size viewportSize,
    required EdgeInsets contentMargins,
    ReadingAnchor? currentAnchor,
    bool notify = true,
  }) {
    final sizeChanged =
        (_viewportSize.width - viewportSize.width).abs() > 1.0 ||
        (_viewportSize.height - viewportSize.height).abs() > 1.0;
    final marginsChanged = _contentMargins != contentMargins;

    if (!sizeChanged && !marginsChanged) {
      if (currentAnchor != null) {
        return restoreFromAnchor(currentAnchor);
      }
      return 0;
    }

    _viewportSize = viewportSize;
    _contentMargins = contentMargins;

    // Viewport dimensions changed; invalidate cached offsets and re-slice measured chapters
    final reMeasured = Map<int, double>.from(_chapterContentHeights);
    _chapterOffsets.clear();
    _chapterContentHeights.clear();

    for (final entry in reMeasured.entries) {
      registerChapterHeight(entry.key, entry.value, notify: false);
    }

    _recomputePrefixSums();
    if (notify) notifyListeners();

    if (currentAnchor != null) {
      return restoreFromAnchor(currentAnchor);
    }
    return 0;
  }

  /// Registers the measured content height of a chapter after layout.
  void registerChapterHeight(
    int chapterIndex,
    double contentHeight, {
    List<({double top, double bottom})>? lineBounds,
    bool notify = true,
  }) {
    if (chapterIndex < 0 || chapterIndex >= _chapterCount) return;

    _chapterContentHeights[chapterIndex] = contentHeight;
    final offsets = _slicer.computePageOffsets(
      contentHeight: contentHeight,
      viewportHeight: availableHeight,
      lineBounds: lineBounds,
    );

    final oldOffsets = _chapterOffsets[chapterIndex];
    _chapterOffsets[chapterIndex] = offsets;
    final newPageCount = math.max(1, offsets.length);

    final pageCountChanged = _pagesPerChapter[chapterIndex] != newPageCount;
    final offsetsChanged = _offsetsChanged(oldOffsets, offsets);

    if (pageCountChanged) {
      _pagesPerChapter[chapterIndex] = newPageCount;
      _recomputePrefixSums();
    }

    if ((pageCountChanged || offsetsChanged) && notify) {
      notifyListeners();
    }
  }

  bool _offsetsChanged(List<double>? a, List<double> b) {
    if (a == null || a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.5) return true;
    }
    return false;
  }

  /// Retrieves the page slice offsets for a specific chapter.
  List<double> getChapterPageOffsets(int chapterIndex) {
    final cached = _chapterOffsets[chapterIndex];
    if (cached != null) return cached;

    // Fallback: 1 page starting at 0.0
    return const [0.0];
  }

  /// Resolves a global page index to its corresponding chapter and page-in-chapter.
  PageCoordinate coordinateFromGlobalPage(int globalPage) {
    if (_chapterCount == 0) {
      return const PageCoordinate(
        chapterIndex: 0,
        pageInChapter: 0,
        totalPagesInChapter: 1,
        globalPage: 0,
      );
    }

    final clampedGlobal = globalPage
        .clamp(0, math.max(0, totalPageCount - 1))
        .toInt();

    // Binary search in prefix sums
    var low = 0;
    var high = _chapterCount - 1;
    var chapter = 0;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final startOfMid = mid == 0 ? 0 : _prefixSums[mid - 1];
      final endOfMid = _prefixSums[mid];

      if (clampedGlobal >= startOfMid && clampedGlobal < endOfMid) {
        chapter = mid;
        break;
      } else if (clampedGlobal < startOfMid) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    final chapterStart = chapter == 0 ? 0 : _prefixSums[chapter - 1];
    final pageInChapter = clampedGlobal - chapterStart;
    final totalInChapter = _pagesPerChapter[chapter];

    return PageCoordinate(
      chapterIndex: chapter,
      pageInChapter: pageInChapter,
      totalPagesInChapter: totalInChapter,
      globalPage: clampedGlobal,
    );
  }

  /// Maps a chapter index and page-in-chapter to a global page index.
  int globalPageFromCoordinate(int chapterIndex, int pageInChapter) {
    if (_chapterCount == 0 || chapterIndex < 0) return 0;
    final clampedChapter = chapterIndex.clamp(0, _chapterCount - 1).toInt();
    final chapterStart = clampedChapter == 0
        ? 0
        : _prefixSums[clampedChapter - 1];
    final totalInChapter = _pagesPerChapter[clampedChapter];
    final clampedPage = pageInChapter
        .clamp(0, math.max(0, totalInChapter - 1))
        .toInt();

    return chapterStart + clampedPage;
  }

  /// Gets the first global page of a given chapter (useful for TOC navigation).
  int getGlobalPageForChapter(int chapterIndex) =>
      globalPageFromCoordinate(chapterIndex, 0);

  /// Captures the current reading anchor from a global page index.
  ReadingAnchor createAnchor(int globalPage) {
    final coord = coordinateFromGlobalPage(globalPage);
    return ReadingAnchor(
      chapterIndex: coord.chapterIndex,
      progressionInChapter: coord.progressionInChapter,
    );
  }

  /// Restores reading position from an anchor after layout or font size changes.
  int restoreFromAnchor(ReadingAnchor anchor) {
    if (_chapterCount == 0) return 0;
    final clampedChapter = anchor.chapterIndex
        .clamp(0, _chapterCount - 1)
        .toInt();
    final totalInChapter = _pagesPerChapter[clampedChapter];

    final pageInChapter = (anchor.progressionInChapter * (totalInChapter - 1))
        .round()
        .clamp(0, math.max(0, totalInChapter - 1))
        .toInt();

    return globalPageFromCoordinate(clampedChapter, pageInChapter);
  }

  /// Resets state when a document is closed or changed.
  void reset() {
    _reader = null;
    _chapterCount = 0;
    _viewportSize = Size.zero;
    _contentMargins = EdgeInsets.zero;
    _chapterOffsets.clear();
    _chapterContentHeights.clear();
    _pagesPerChapter = [];
    _prefixSums = [];
    notifyListeners();
  }

  void _recomputePrefixSums() {
    _prefixSums = List.filled(_chapterCount, 0);
    var runningSum = 0;
    for (var i = 0; i < _chapterCount; i++) {
      runningSum += _pagesPerChapter[i];
      _prefixSums[i] = runningSum;
    }
  }

  @override
  void dispose() {
    _chapterOffsets.clear();
    _chapterContentHeights.clear();
    super.dispose();
  }
}
