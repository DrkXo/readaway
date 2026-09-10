import 'package:flutter/material.dart';

import '../../../controllers/reader_viewport_controller.dart';
import 'continuous_scroll_coordinator.dart';

/// A continuous, seamless vertical scroll view for webtoon-style reading.
class ContinuousReaderView extends StatefulWidget {
  const ContinuousReaderView({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.itemBuilder,
    required this.onPageChangeRequested,
    this.controller,
    this.bottomPadding = 0.0,
  });

  final int currentPage;
  final int pageCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ValueChanged<int> onPageChangeRequested;
  final ReaderViewportController? controller;
  final double bottomPadding;

  @override
  State<ContinuousReaderView> createState() => _ContinuousReaderViewState();
}

class _ContinuousReaderViewState extends State<ContinuousReaderView> {
  late final ScrollController _scrollController;
  late final ContinuousScrollCoordinator _scrollCoordinator;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollCoordinator = ContinuousScrollCoordinator(
      scrollController: _scrollController,
      pageCount: widget.pageCount,
      onPageChanged: widget.onPageChangeRequested,
    );
    _bindController();

    if (widget.currentPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollCoordinator.jumpToPage(widget.currentPage);
      });
    }
  }

  void _bindController() {
    final controller = widget.controller;
    if (controller == null) return;

    controller.updatePageCount(widget.pageCount);
    controller.animateToPageDelegate = _scrollCoordinator.animateToPage;
    controller.jumpToPageDelegate = _scrollCoordinator.jumpToPage;
    controller.attachedScrollController = _scrollController;
  }

  void _unbindController(ReaderViewportController? controller) {
    if (controller == null) return;

    controller.animateToPageDelegate = null;
    controller.jumpToPageDelegate = null;
    if (controller.attachedScrollController == _scrollController) {
      controller.attachedScrollController = null;
    }
  }

  @override
  void didUpdateWidget(ContinuousReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _unbindController(oldWidget.controller);
      _bindController();
    } else if (widget.pageCount != oldWidget.pageCount) {
      widget.controller?.updatePageCount(widget.pageCount);
    }

    _scrollCoordinator.updatePageCount(widget.pageCount);
    if (widget.currentPage != _scrollCoordinator.lastReportedPage &&
        !_scrollCoordinator.isProgrammaticScroll) {
      _scrollCoordinator.jumpToPage(widget.currentPage);
    }
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    _scrollCoordinator.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          _scrollCoordinator.detectVisiblePage();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        itemCount: widget.pageCount,
        itemBuilder: (context, index) {
          return KeyedSubtree(
            key: _scrollCoordinator.keyForIndex(index),
            child: RepaintBoundary(
              child: widget.itemBuilder(context, index),
            ),
          );
        },
      ),
    );
  }
}
