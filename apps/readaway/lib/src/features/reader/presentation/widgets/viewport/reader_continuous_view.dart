import 'package:flutter/material.dart';

import '../../controllers/reader_page_view_controller.dart';

/// A continuous, seamless vertical scroll view for webtoon-style or infinite vertical reading.
///
/// Activated when `prefs.scrollDirection == ReaderScrollDirection.vertical` and `prefs.pageSnap == false`.
class ReaderContinuousView extends StatefulWidget {
  const ReaderContinuousView({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.itemBuilder,
    required this.onPageChangeRequested,
    this.controller,
  });

  final int currentPage;
  final int pageCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ValueChanged<int> onPageChangeRequested;
  final ReaderPageViewController? controller;

  @override
  State<ReaderContinuousView> createState() => _ReaderContinuousViewState();
}

class _ReaderContinuousViewState extends State<ReaderContinuousView> {
  late final ScrollController _scrollController;
  final Map<int, GlobalKey> _pageKeys = {};
  bool _isProgrammaticScroll = false;
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.currentPage;
    _scrollController = ScrollController();
    _bindController();
    if (widget.currentPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _jumpToPage(widget.currentPage);
        }
      });
    }
  }

  void _bindController() {
    final c = widget.controller;
    if (c != null) {
      c.updatePageCount(widget.pageCount);
      c.animateToPageDelegate = _animateToPage;
      c.jumpToPageDelegate = _jumpToPage;
    }
  }

  void _unbindController(ReaderPageViewController? c) {
    if (c != null) {
      c.animateToPageDelegate = null;
      c.jumpToPageDelegate = null;
    }
  }

  @override
  void didUpdateWidget(ReaderContinuousView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _unbindController(oldWidget.controller);
      _bindController();
    } else if (widget.pageCount != oldWidget.pageCount) {
      widget.controller?.updatePageCount(widget.pageCount);
    }

    if (widget.currentPage != _lastReportedPage && !_isProgrammaticScroll) {
      _jumpToPage(widget.currentPage);
    }
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _animateToPage(
    int page, {
    Duration? duration,
    Curve? curve,
  }) async {
    final key = _pageKeys[page];
    final currentCtx = key?.currentContext;
    if (currentCtx != null) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      await Scrollable.ensureVisible(
        currentCtx,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOutCubic,
        alignment: 0.0,
      );
      _isProgrammaticScroll = false;
      widget.onPageChangeRequested(page);
    } else if (_scrollController.hasClients) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final count = widget.pageCount > 0 ? widget.pageCount : 1;
      final estimatedOffset = (page / count * maxExtent).clamp(0.0, maxExtent);
      await _scrollController.animateTo(
        estimatedOffset,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOutCubic,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final retryCtx = _pageKeys[page]?.currentContext;
        if (retryCtx != null) {
          Scrollable.ensureVisible(
            retryCtx,
            duration: Duration.zero,
            alignment: 0.0,
          );
        }
        _isProgrammaticScroll = false;
        widget.onPageChangeRequested(page);
      });
    }
  }

  void _jumpToPage(int page) {
    final key = _pageKeys[page];
    final currentCtx = key?.currentContext;
    if (currentCtx != null) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      Scrollable.ensureVisible(
        currentCtx,
        duration: Duration.zero,
        alignment: 0.0,
      );
      _isProgrammaticScroll = false;
      widget.onPageChangeRequested(page);
    } else if (_scrollController.hasClients) {
      _isProgrammaticScroll = true;
      _lastReportedPage = page;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final count = widget.pageCount > 0 ? widget.pageCount : 1;
      final estimatedOffset = (page / count * maxExtent).clamp(0.0, maxExtent);
      _scrollController.jumpTo(estimatedOffset);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final retryCtx = _pageKeys[page]?.currentContext;
        if (retryCtx != null) {
          Scrollable.ensureVisible(
            retryCtx,
            duration: Duration.zero,
            alignment: 0.0,
          );
        }
        _isProgrammaticScroll = false;
        widget.onPageChangeRequested(page);
      });
    }
  }

  GlobalKey _keyForIndex(int index) {
    return _pageKeys.putIfAbsent(index, () => GlobalKey(debugLabel: 'continuous_page_$index'));
  }

  void _detectVisiblePage() {
    if (_isProgrammaticScroll || !_scrollController.hasClients) return;

    int? candidatePage;
    double minDistance = double.infinity;

    for (final entry in _pageKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx != null && ctx.findRenderObject() is RenderBox) {
        final box = ctx.findRenderObject()! as RenderBox;
        if (!box.hasSize) continue;
        final pos = box.localToGlobal(Offset.zero);
        final dist = (pos.dy - 100).abs();
        if (dist < minDistance) {
          minDistance = dist;
          candidatePage = entry.key;
        }
      }
    }

    if (candidatePage != null && candidatePage != _lastReportedPage) {
      _lastReportedPage = candidatePage;
      widget.onPageChangeRequested(candidatePage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          _detectVisiblePage();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: widget.pageCount,
        itemBuilder: (context, index) {
          return KeyedSubtree(
            key: _keyForIndex(index),
            child: RepaintBoundary(
              child: widget.itemBuilder(context, index),
            ),
          );
        },
      ),
    );
  }
}
