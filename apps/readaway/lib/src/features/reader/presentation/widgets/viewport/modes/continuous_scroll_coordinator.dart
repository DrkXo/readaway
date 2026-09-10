import 'package:flutter/material.dart';

class ContinuousScrollCoordinator {
  ContinuousScrollCoordinator({
    required this._scrollController,
    required this._pageCount,
    required this._onPageChanged,
  });

  final ScrollController _scrollController;
  final ValueChanged<int> _onPageChanged;
  final Map<int, GlobalKey> _pageKeys = {};
  int _pageCount;
  bool _isProgrammaticScroll = false;
  int _lastReportedPage = 0;
  bool _disposed = false;

  int get lastReportedPage => _lastReportedPage;
  bool get isProgrammaticScroll => _isProgrammaticScroll;

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
      _onPageChanged(page);
    } else if (_scrollController.hasClients) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      _scrollController.jumpTo(_estimatedOffset(page));
      _scheduleEnsureVisible(page);
    }
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
