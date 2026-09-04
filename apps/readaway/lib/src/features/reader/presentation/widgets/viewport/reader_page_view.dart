import 'package:flutter/material.dart';

import '../../../../settings/domain/models/reader_preferences.dart';
import '../../extensions/reader_page_transition_extension.dart';

/// A state-driven, keyed page view for the reader.
///
/// Unlike [PageView] (which lays pages in a scrollable strip and transitions
/// purely by scroll offset), this widget holds a single "current page" index
/// and animates between pages with an [AnimationController]. That makes
/// arbitrary transitions possible — [ReaderPageTransition.none], [fade],
/// [slide] and [sharedAxis] — in either [ReaderScrollDirection.horizontal] or
/// [vertical].
///
/// The widget is *controlled*: the parent owns the current page index (the
/// reader BLoC is the source of truth) and passes it via [currentPage]. When
/// it changes, this widget runs the configured transition. Swipe gestures
/// report a requested page change through [onPageChangeRequested].
///
/// Pages are keyed by their index so per-page state (e.g. the vertical
/// [ScrollController] owned by each reflowable page) is preserved across
/// transitions.
class ReaderPageView extends StatefulWidget {
  const ReaderPageView({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.transition,
    required this.direction,
    required this.itemBuilder,
    required this.onPageChangeRequested,
    this.duration = const Duration(milliseconds: 250),
  });

  /// The currently displayed page index (0-based).
  final int currentPage;

  /// Total number of pages.
  final int pageCount;

  /// Which transition to play between pages.
  final ReaderPageTransition transition;

  /// Scroll/paging direction.
  final ReaderScrollDirection direction;

  /// Builds the widget for the page at [index].
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Called when the user swipes to request a page change (target index).
  final ValueChanged<int> onPageChangeRequested;

  /// Duration of the transition animation.
  final Duration duration;

  @override
  State<ReaderPageView> createState() => _ReaderPageViewState();
}

class _ReaderPageViewState extends State<ReaderPageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _currentPage;
  int? _previousPage;
  bool _animating = false;
  bool _goingForward = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.currentPage;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(ReaderPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage != _currentPage) {
      final goingForward = widget.currentPage > _currentPage;
      _previousPage = _currentPage;
      _currentPage = widget.currentPage;
      _animating = true;
      _goingForward = goingForward;
      _controller
        ..value = 0
        ..forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _animating = false;
        _previousPage = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSwipe(double velocity) {
    const threshold = 200.0;
    if (velocity < -threshold) {
      widget.onPageChangeRequested(_currentPage + 1);
    } else if (velocity > threshold) {
      widget.onPageChangeRequested(_currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.direction == ReaderScrollDirection.horizontal;
    return Semantics(
      label: 'Page ${_currentPage + 1} of ${widget.pageCount}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: horizontal
            ? (d) => _onSwipe(d.primaryVelocity ?? 0)
            : null,
        onVerticalDragEnd: horizontal
            ? null
            : (d) => _onSwipe(d.primaryVelocity ?? 0),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_animating && _previousPage != null)
                _buildPage(_previousPage!, outgoing: true),
              _buildPage(_currentPage, outgoing: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index, {required bool outgoing}) {
    // Key each page by its index so per-page state (e.g. the vertical
    // ScrollController owned by each reflowable page) is preserved and
    // correctly associated across transitions, even when adjacent pages
    // share the same widget type.
    final page = KeyedSubtree(
      key: ValueKey<int>(index),
      child: widget.itemBuilder(context, index),
    );
    if (!_animating) return page;

    return AnimatedBuilder(
      animation: _controller,
      child: page,
      builder: (context, child) {
        final t = _controller.value;
        return widget.transition.applyTransition(
          child!,
          t,
          outgoing: outgoing,
          horizontal: widget.direction == ReaderScrollDirection.horizontal,
          goingForward: _goingForward,
        );
      },
    );
  }
}
