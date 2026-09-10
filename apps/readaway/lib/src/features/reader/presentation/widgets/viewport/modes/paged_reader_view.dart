import 'package:flutter/material.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

import '../../../controllers/reader_viewport_controller.dart';
import '../../../transitions/transitions.dart';
import 'paged_transition_controller.dart';

/// A high-performance, interactive, gesture-driven page view for the reader.
class PagedReaderView extends StatefulWidget {
  const PagedReaderView({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.transition,
    required this.direction,
    required this.itemBuilder,
    required this.onPageChangeRequested,
    this.controller,
    this.duration = const Duration(milliseconds: 320),
    this.backgroundColor,
  });

  final Color? backgroundColor;
  final int currentPage;
  final int pageCount;
  final ReaderPageTransition transition;
  final ReaderScrollDirection direction;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ValueChanged<int> onPageChangeRequested;
  final ReaderViewportController? controller;
  final Duration duration;

  @override
  State<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends State<PagedReaderView>
    with SingleTickerProviderStateMixin {
  late final PagedTransitionController _transitionController;

  @override
  void initState() {
    super.initState();
    _transitionController = PagedTransitionController(
      vsync: this,
      currentPage: widget.currentPage,
      pageCount: widget.pageCount,
      transition: widget.transition,
      direction: widget.direction,
      duration: widget.duration,
      viewportController: widget.controller,
      onPageCommitted: widget.onPageChangeRequested,
    )..addListener(_requestRebuild);
    _bindController();
  }

  void _requestRebuild() {
    if (mounted) setState(() {});
  }

  void _bindController() {
    final controller = widget.controller;
    if (controller == null) return;

    controller.updatePageCount(widget.pageCount);
    controller.animateToPageDelegate = _transitionController.animateToPage;
    controller.jumpToPageDelegate = _transitionController.jumpToPage;
    controller.dragStartDelegate = _transitionController.handleDragStart;
    controller.dragUpdateDelegate = _transitionController.handleDragUpdate;
    controller.dragEndDelegate = _transitionController.handleDragEnd;
    controller.dragCancelDelegate = _transitionController.handleDragCancel;
  }

  void _unbindController(ReaderViewportController? controller) {
    if (controller == null) return;

    controller.animateToPageDelegate = null;
    controller.jumpToPageDelegate = null;
    controller.dragStartDelegate = null;
    controller.dragUpdateDelegate = null;
    controller.dragEndDelegate = null;
    controller.dragCancelDelegate = null;
  }

  @override
  void didUpdateWidget(PagedReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _unbindController(oldWidget.controller);
      _bindController();
    } else if (widget.pageCount != oldWidget.pageCount) {
      widget.controller?.updatePageCount(widget.pageCount);
    }

    _transitionController.updateConfiguration(
      pageCount: widget.pageCount,
      transition: widget.transition,
      direction: widget.direction,
      duration: widget.duration,
    );
    _transitionController.syncCurrentPage(widget.currentPage);
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    _transitionController
      ..removeListener(_requestRebuild)
      ..dispose();
    super.dispose();
  }

  Widget _buildPageLayer(
    BuildContext context,
    int pageIndex,
    Color backgroundColor,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(
        child: widget.itemBuilder(context, pageIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackground =
        widget.backgroundColor ??
        Theme.of(context).extension<AppColors>()?.readerBackground ??
        Theme.of(context).scaffoldBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final currentPage = _transitionController.currentPage;
        final targetPage = _transitionController.targetPage;

        Widget content;
        if (targetPage == null || targetPage == currentPage) {
          content = RepaintBoundary(
            key: ValueKey<int>(currentPage),
            child: _buildPageLayer(context, currentPage, effectiveBackground),
          );
        } else {
          final strategy = ReaderPageTransitionFactory.get(widget.transition);
          final metrics = PageTransitionMetrics(
            viewportSize: viewportSize,
            direction: widget.direction,
            isForward: _transitionController.isForward,
          );
          final outgoing = RepaintBoundary(
            key: ValueKey<int>(currentPage),
            child: _buildPageLayer(context, currentPage, effectiveBackground),
          );
          final incoming = RepaintBoundary(
            key: ValueKey<int>(targetPage),
            child: _buildPageLayer(context, targetPage, effectiveBackground),
          );

          content = AnimatedBuilder(
            animation: _transitionController.animationController,
            builder: (context, _) {
              final progress = _transitionController.isInteractive
                  ? _transitionController.animationController.value
                  : _transitionController.curvedAnimation.value;
              return strategy.buildTransition(
                context: context,
                outgoingPage: outgoing,
                incomingPage: incoming,
                progress: progress,
                metrics: metrics,
              );
            },
          );
        }

        return Semantics(
          label: 'Page ${currentPage + 1} of ${widget.pageCount}',
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _transitionController.handlePointerSignal,
            child: ColoredBox(
              color: effectiveBackground,
              child: ClipRect(child: content),
            ),
          ),
        );
      },
    );
  }
}
