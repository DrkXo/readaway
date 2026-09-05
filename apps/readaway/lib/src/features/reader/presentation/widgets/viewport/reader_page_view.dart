import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import '../../controllers/reader_page_view_controller.dart';
import '../../transitions/transitions.dart';

/// A high-performance, interactive, gesture-driven page view for the reader.
///
/// Features:
/// - 1:1 Interactive finger tracking (finger drag moves the page in real time).
/// - Physics-based snapping and fling velocity completion.
/// - Pluggable [ReaderPageTransitionStrategy] support (Slide, Cover, Fade, Shared Axis, Curl, None).
/// - RepaintBoundary isolation to avoid repainting complex DOM/rich-text subtrees during animations.
/// - Full coordination with [ReaderPageViewController] for programmatic and keyboard navigation.
class ReaderPageView extends StatefulWidget {
  const ReaderPageView({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.transition,
    required this.direction,
    required this.itemBuilder,
    required this.onPageChangeRequested,
    this.controller,
    this.duration = const Duration(milliseconds: 320),
  });

  /// Current 0-based page index.
  final int currentPage;

  /// Total page count.
  final int pageCount;

  /// Transition effect to apply.
  final ReaderPageTransition transition;

  /// Horizontal or vertical paging direction.
  final ReaderScrollDirection direction;

  /// Widget builder for page at [index].
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Callback when page commit is completed.
  final ValueChanged<int> onPageChangeRequested;

  /// Shared reader navigation controller.
  final ReaderPageViewController? controller;

  /// Standard duration for programmatic transitions.
  final Duration duration;

  @override
  State<ReaderPageView> createState() => _ReaderPageViewState();
}

class _ReaderPageViewState extends State<ReaderPageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late CurvedAnimation _curvedAnim;

  int _currentPage = 0;
  int? _targetPage;
  bool _isForward = true;
  bool _isInteractive = false;
  double _rawDragProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.currentPage;
    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(_onAnimationTick)
     ..addStatusListener(_onAnimationStatus);

    _curvedAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _bindController();
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
  void didUpdateWidget(ReaderPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _unbindController(oldWidget.controller);
      _bindController();
    } else if (widget.pageCount != oldWidget.pageCount) {
      widget.controller?.updatePageCount(widget.pageCount);
    }

    // External state change from BLoC (e.g. TOC jump, direct state change)
    if (widget.currentPage != _currentPage && !_animController.isAnimating && !_isInteractive) {
      final isFwd = widget.currentPage > _currentPage;
      if (widget.transition == ReaderPageTransition.none) {
        setState(() {
          _currentPage = widget.currentPage;
          _targetPage = null;
        });
      } else {
        _startAnimation(
          from: _currentPage,
          to: widget.currentPage,
          forward: isFwd,
        );
      }
    }
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    _curvedAnim.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!_isInteractive) {
      widget.controller?.setInteractionState(
        isAnimating: _animController.isAnimating,
        dragProgress: _curvedAnim.value,
      );
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _finalizeTransition(committed: true);
    } else if (status == AnimationStatus.dismissed) {
      _finalizeTransition(committed: false);
    }
  }

  void _finalizeTransition({required bool committed}) {
    if (_targetPage != null && committed) {
      final newPage = _targetPage!;
      setState(() {
        _currentPage = newPage;
        _targetPage = null;
        _isInteractive = false;
      });
      widget.onPageChangeRequested(newPage);
    } else {
      setState(() {
        _targetPage = null;
        _isInteractive = false;
      });
    }
    _animController.value = 0.0;
    widget.controller?.setInteractionState(
      isAnimating: false,
      isDragging: false,
      dragProgress: 0.0,
    );
  }

  Future<void> _animateToPage(
    int target, {
    Duration? duration,
    Curve? curve,
  }) async {
    if (target < 0 || target >= widget.pageCount) return;
    if (target == _currentPage && !_animController.isAnimating) return;

    if (widget.transition == ReaderPageTransition.none) {
      _jumpToPage(target);
      return;
    }

    _animController.stop();
    _startAnimation(
      from: _currentPage,
      to: target,
      forward: target > _currentPage,
      customDuration: duration,
      customCurve: curve,
    );
  }

  void _jumpToPage(int target) {
    if (target < 0 || target >= widget.pageCount) return;
    _animController.stop();
    setState(() {
      _currentPage = target;
      _targetPage = null;
      _isInteractive = false;
    });
    widget.onPageChangeRequested(target);
  }

  void _startAnimation({
    required int from,
    required int to,
    required bool forward,
    Duration? customDuration,
    Curve? customCurve,
  }) {
    setState(() {
      _currentPage = from;
      _targetPage = to;
      _isForward = forward;
      _isInteractive = false;
    });

    if (customCurve != null) {
      _curvedAnim.curve = customCurve;
    } else {
      _curvedAnim.curve = Curves.easeOutCubic;
    }

    _animController.duration = customDuration ?? widget.duration;
    _animController.forward(from: 0.0);
  }

  // --- Interactive Drag Handling ---

  void _handleDragStart(DragStartDetails details) {
    if (_animController.isAnimating) {
      _animController.stop();
    }
    _isInteractive = true;
    _rawDragProgress = 0.0;
    widget.controller?.setInteractionState(isDragging: true);
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    Size viewportSize, {
    bool isHorizontalDrag = true,
  }) {
    if (widget.pageCount <= 1) return;

    final primaryDelta = details.primaryDelta ?? 0.0;
    final dimension = isHorizontalDrag ? viewportSize.width : viewportSize.height;
    if (dimension <= 0) return;

    // Moving left/up means delta < 0 -> advancing to next page (forward)
    // Moving right/down means delta > 0 -> going to previous page (backward)
    final deltaNormalized = -primaryDelta / dimension;
    _rawDragProgress += deltaNormalized;

    final targetForward = _rawDragProgress >= 0;
    final potentialTarget = targetForward ? _currentPage + 1 : _currentPage - 1;

    // Check boundary limit
    if (potentialTarget < 0 || potentialTarget >= widget.pageCount) {
      // Apply rubber band dampening at ends
      _rawDragProgress *= 0.85;
      return;
    }

    if (_targetPage != potentialTarget || _isForward != targetForward) {
      setState(() {
        _isForward = targetForward;
        _targetPage = potentialTarget;
      });
    }

    final visualProgress = _rawDragProgress.abs().clamp(0.0, 1.0);
    _animController.value = visualProgress;
    widget.controller?.setInteractionState(dragProgress: visualProgress);
  }

  void _handleDragEnd(
    DragEndDetails details,
    Size viewportSize, {
    bool isHorizontalDrag = true,
  }) {
    if (!_isInteractive || _targetPage == null) {
      _isInteractive = false;
      return;
    }

    final velocity = -(details.primaryVelocity ?? 0.0);

    final currentProgress = _animController.value;
    final movingInTargetDirection = (_isForward && velocity > 0) || (!_isForward && velocity < 0);
    final isFling = movingInTargetDirection && velocity.abs() > 300.0;
    final passedThreshold = currentProgress >= 0.3;

    final commit = isFling || passedThreshold;

    if (commit) {
      // Complete to 1.0
      _curvedAnim.curve = Curves.easeOutCubic;
      final remaining = (1.0 - currentProgress).clamp(0.05, 1.0);
      final durationMs = (widget.duration.inMilliseconds * remaining).round().clamp(100, 400);
      _animController.duration = Duration(milliseconds: durationMs);
      _animController.forward(from: currentProgress);
    } else {
      // Snap back to 0.0
      _curvedAnim.curve = Curves.easeOutCubic;
      final durationMs = (widget.duration.inMilliseconds * currentProgress).round().clamp(80, 300);
      _animController.duration = Duration(milliseconds: durationMs);
      _animController.reverse(from: currentProgress);
    }
  }

  DateTime _lastPointerScrollTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final now = DateTime.now();
      if (now.difference(_lastPointerScrollTime).inMilliseconds < 350) {
        return;
      }

      final isVertical = widget.direction == ReaderScrollDirection.vertical;
      final delta = isVertical
          ? event.scrollDelta.dy
          : (event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy);

      if (delta.abs() > 15) {
        _lastPointerScrollTime = now;
        if (delta > 0) {
          // Scroll down / right -> forward
          if (_currentPage < widget.pageCount - 1) {
            _animateToPage(_currentPage + 1);
          }
        } else {
          // Scroll up / left -> backward
          if (_currentPage > 0) {
            _animateToPage(_currentPage - 1);
          }
        }
      }
    }
  }

  void _handleDragCancel() {
    if (_isInteractive) {
      _curvedAnim.curve = Curves.easeOutCubic;
      _animController.reverse(from: _animController.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.direction == ReaderScrollDirection.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        Widget content;
        if (_targetPage == null || _targetPage == _currentPage) {
          // Static single page when idle: zero transition overhead
          content = RepaintBoundary(
            key: ValueKey<int>(_currentPage),
            child: widget.itemBuilder(context, _currentPage),
          );
        } else {
          // Active transition rendering with isolated RepaintBoundaries
          final strategy = ReaderPageTransitionFactory.get(widget.transition);
          final metrics = PageTransitionMetrics(
            viewportSize: viewportSize,
            direction: widget.direction,
            isForward: _isForward,
          );

          final outgoingWidget = RepaintBoundary(
            key: ValueKey<int>(_currentPage),
            child: widget.itemBuilder(context, _currentPage),
          );

          final incomingWidget = RepaintBoundary(
            key: ValueKey<int>(_targetPage!),
            child: widget.itemBuilder(context, _targetPage!),
          );

          content = AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final progress = _isInteractive
                  ? _animController.value
                  : _curvedAnim.value;

              return strategy.buildTransition(
                context: context,
                outgoingPage: outgoingWidget,
                incomingPage: incomingWidget,
                progress: progress,
                metrics: metrics,
              );
            },
          );
        }

        return Semantics(
          label: 'Page ${_currentPage + 1} of ${widget.pageCount}',
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: horizontal ? _handleDragStart : null,
              onHorizontalDragUpdate: horizontal
                  ? (d) => _handleDragUpdate(
                        d,
                        viewportSize,
                        isHorizontalDrag: true,
                      )
                  : null,
              onHorizontalDragEnd: horizontal
                  ? (d) => _handleDragEnd(
                        d,
                        viewportSize,
                        isHorizontalDrag: true,
                      )
                  : null,
              onHorizontalDragCancel: horizontal ? _handleDragCancel : null,
              onVerticalDragStart: !horizontal ? _handleDragStart : null,
              onVerticalDragUpdate: !horizontal
                  ? (d) => _handleDragUpdate(
                        d,
                        viewportSize,
                        isHorizontalDrag: false,
                      )
                  : null,
              onVerticalDragEnd: !horizontal
                  ? (d) => _handleDragEnd(
                        d,
                        viewportSize,
                        isHorizontalDrag: false,
                      )
                  : null,
              onVerticalDragCancel: !horizontal ? _handleDragCancel : null,
              child: ClipRect(child: content),
            ),
          ),
        );
      },
    );
  }
}
