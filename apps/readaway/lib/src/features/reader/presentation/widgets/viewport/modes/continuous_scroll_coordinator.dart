import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:readaway_core/readaway_core.dart';

class ContinuousScrollCoordinator {
  ContinuousScrollCoordinator({
    required this._scrollController,
    required this._pageCount,
    required this._onPageChanged,
    this.onAnchorChanged,
    this.onRestoreComplete,
  });

  final ScrollController _scrollController;
  final ValueChanged<int> _onPageChanged;
  final Map<int, GlobalKey> _pageKeys = {};
  int _pageCount;
  bool _isProgrammaticScroll = false;
  int _lastReportedPage = 0;
  bool _disposed = false;
  ReadingAnchor? _currentAnchor;

  /// Called whenever the reading position (chapter + progression) changes.
  final ValueChanged<ReadingAnchor>? onAnchorChanged;

  /// Called once a [restoreToAnchor] has finished scrolling to the anchor.
  final VoidCallback? onRestoreComplete;

  int get lastReportedPage => _lastReportedPage;
  bool get isProgrammaticScroll => _isProgrammaticScroll;

  /// The most recently computed reading position.
  ReadingAnchor? get currentAnchor => _currentAnchor;

  void updatePageCount(int pageCount) {
    _pageCount = pageCount;
  }

  void setCurrentPage(int page) {
    _lastReportedPage = page;
  }

  GlobalKey keyForIndex(int index) {
    return _pageKeys.putIfAbsent(
      index,
      () => GlobalKey(debugLabel: 'continuous_page_$index'),
    );
  }

  Future<void> animateToPage(
    int page, {
    Duration? duration,
    Curve? curve,
  }) async {
    final key = _pageKeys[page];
    final currentContext = key?.currentContext;
    if (currentContext != null) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      await Scrollable.ensureVisible(
        currentContext,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOutCubic,
        alignment: 0.0,
      );
      _isProgrammaticScroll = false;
      reportAnchor();
      _onPageChanged(page);
    } else if (_scrollController.hasClients) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      await _scrollController.animateTo(
        _estimatedOffset(page),
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOutCubic,
      );
      _scheduleEnsureVisible(page);
    }
  }

  void jumpToPage(int page) {
    final key = _pageKeys[page];
    final currentContext = key?.currentContext;
    if (currentContext != null) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      Scrollable.ensureVisible(
        currentContext,
        duration: Duration.zero,
        alignment: 0.0,
      );
      _isProgrammaticScroll = false;
      reportAnchor();
      _onPageChanged(page);
    } else if (_scrollController.hasClients) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      _scrollController.jumpTo(_estimatedOffset(page));
      _scheduleEnsureVisible(page);
    }
  }

  /// Restores the scroll position to a saved [ReadingAnchor].
  ///
  /// Jumps to the anchor's chapter, then refines the scroll offset to the
  /// exact progression once the chapter has been laid out.
  Future<void> restoreToAnchor(ReadingAnchor anchor) async {
    final key = _pageKeys[anchor.chapterIndex];
    final currentContext = key?.currentContext;
    if (currentContext != null) {
      _isProgrammaticScroll = true;
      _lastReportedPage = anchor.chapterIndex;
      await Scrollable.ensureVisible(
        currentContext,
        duration: Duration.zero,
        alignment: 0.0,
      );
      _refineToProgression(anchor);
      _isProgrammaticScroll = false;
      _setAnchor(anchor);
      _onPageChanged(anchor.chapterIndex);
      onRestoreComplete?.call();
    } else if (_scrollController.hasClients) {
      _isProgrammaticScroll = true;
      _lastReportedPage = anchor.chapterIndex;
      _scrollController.jumpTo(_estimatedOffset(anchor.chapterIndex));
      _scheduleRestoreRefine(anchor);
    }
  }

  /// Computes the current reading anchor from the scroll position.
  ReadingAnchor? computeCurrentAnchor() {
    if (!_scrollController.hasClients) return null;
    final pixels = _scrollController.position.pixels;

    int? visiblePage;
    var minDistance = double.infinity;
    RenderBox? visibleBox;
    for (final entry in _pageKeys.entries) {
      final context = entry.value.currentContext;
      final renderObject = context?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;
      final position = renderObject.localToGlobal(Offset.zero);
      final distance = (position.dy - 100).abs();
      if (distance < minDistance) {
        minDistance = distance;
        visiblePage = entry.key;
        visibleBox = renderObject;
      }
    }
    if (visiblePage == null || visibleBox == null) return null;

    final viewport = RenderAbstractViewport.of(visibleBox);
    final reveal = viewport.getOffsetToReveal(visibleBox, 0.0);
    final offsetInChapter = (pixels - reveal.offset).clamp(
      0.0,
      visibleBox.size.height,
    );
    final progression = visibleBox.size.height > 0
        ? (offsetInChapter / visibleBox.size.height).clamp(0.0, 1.0)
        : 0.0;
    return ReadingAnchor(
      chapterIndex: visiblePage,
      progressionInChapter: progression,
    );
  }

  /// Recomputes and reports the current reading anchor.
  void reportAnchor() {
    final anchor = computeCurrentAnchor();
    if (anchor != null) _setAnchor(anchor);
  }

  void _setAnchor(ReadingAnchor anchor) {
    if (anchor == _currentAnchor) return;
    _currentAnchor = anchor;
    onAnchorChanged?.call(anchor);
  }

  void _refineToProgression(ReadingAnchor anchor) {
    if (!_scrollController.hasClients) return;
    final context = _pageKeys[anchor.chapterIndex]?.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final itemHeight = renderObject.size.height;
    if (itemHeight <= 0) return;
    final target =
        _scrollController.position.pixels +
        anchor.progressionInChapter * itemHeight;
    _scrollController.jumpTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  void _scheduleRestoreRefine(ReadingAnchor anchor, {int attempts = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      final context = _pageKeys[anchor.chapterIndex]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration.zero,
          alignment: 0.0,
        );
        _refineToProgression(anchor);
        _isProgrammaticScroll = false;
        _setAnchor(anchor);
        _onPageChanged(anchor.chapterIndex);
        onRestoreComplete?.call();
      } else if (attempts < 5) {
        _scheduleRestoreRefine(anchor, attempts: attempts + 1);
      } else {
        _isProgrammaticScroll = false;
        _setAnchor(anchor);
        _onPageChanged(anchor.chapterIndex);
        onRestoreComplete?.call();
      }
    });
  }

  void detectVisiblePage() {
    if (_isProgrammaticScroll || !_scrollController.hasClients) return;

    int? candidatePage;
    var minDistance = double.infinity;
    for (final entry in _pageKeys.entries) {
      final context = entry.value.currentContext;
      final renderObject = context?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;

      final position = renderObject.localToGlobal(Offset.zero);
      final distance = (position.dy - 100).abs();
      if (distance < minDistance) {
        minDistance = distance;
        candidatePage = entry.key;
      }
    }

    if (candidatePage != null && candidatePage != _lastReportedPage) {
      _lastReportedPage = candidatePage;
      reportAnchor();
      _onPageChanged(candidatePage);
    }
  }

  void _scheduleEnsureVisible(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      final context = _pageKeys[page]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration.zero,
          alignment: 0.0,
        );
      }
      _isProgrammaticScroll = false;
      reportAnchor();
      _onPageChanged(page);
    });
  }

  double _estimatedOffset(int page) {
    final maxExtent = _scrollController.position.maxScrollExtent;
    final count = _pageCount > 0 ? _pageCount : 1;
    return (page / count * maxExtent).clamp(0.0, maxExtent);
  }

  void dispose() {
    _disposed = true;
    _pageKeys.clear();
  }
}
