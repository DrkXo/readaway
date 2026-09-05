import 'package:flutter/widgets.dart';

/// Central navigation and interaction controller for the reader viewport.
///
/// Coordinates:
/// - Programmatic page jumps and smooth animated transitions (TOC, keyboard shortcuts, bottom bar).
/// - Interactive gestures (1:1 finger tracking, fling, snap).
/// - Overscroll handoff from inner scrollable pages (solving the end-of-page vertical scroll lock).
/// - Synchronization with the reader BLoC as the single source of truth.
class ReaderPageViewController extends ChangeNotifier {
  ReaderPageViewController({
    int initialPage = 0,
    int initialPageCount = 0,
    int? pageCount,
  })  : _currentPage = initialPage,
        _pageCount = pageCount ?? initialPageCount;

  int _currentPage;
  int _pageCount;
  bool _isAnimating = false;
  bool _isDragging = false;
  double _dragProgress = 0.0;

  /// Delegate for animated navigation provided by the active viewport widget (e.g. ReaderPageView).
  Future<void> Function(int targetPage, {Duration? duration, Curve? curve})?
      animateToPageDelegate;

  /// Delegate for instantaneous jump provided by the active viewport widget.
  void Function(int targetPage)? jumpToPageDelegate;

  /// Set by the owner (ReaderPage / ReaderControllerMixin) to notify BLoC of page changes.
  void Function(int index)? onNavigate;

  /// The currently active page index (0-based).
  int get currentPage => _currentPage;

  /// Total number of pages in the document.
  int get pageCount => _pageCount;

  /// Whether an automated transition animation is currently running.
  bool get isAnimating => _isAnimating;

  /// Whether the user is actively dragging the page.
  bool get isDragging => _isDragging;

  /// Current interactive drag progress (0.0 to 1.0).
  double get dragProgress => _dragProgress;

  /// Updates the total page count.
  void updatePageCount(int count) {
    if (_pageCount == count) return;
    _pageCount = count;
    notifyListeners();
  }

  /// Updates current page index without triggering navigation delegate.
  void setCurrentPage(int index) {
    if (_currentPage == index) return;
    _currentPage = index;
    notifyListeners();
  }

  /// Sets whether an animation or drag is currently active.
  void setInteractionState({
    bool? isAnimating,
    bool? isDragging,
    double? dragProgress,
  }) {
    var changed = false;
    if (isAnimating != null && _isAnimating != isAnimating) {
      _isAnimating = isAnimating;
      changed = true;
    }
    if (isDragging != null && _isDragging != isDragging) {
      _isDragging = isDragging;
      changed = true;
    }
    if (dragProgress != null && _dragProgress != dragProgress) {
      _dragProgress = dragProgress;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Requests navigation to [index], using animated transition if available.
  Future<void> goToPage(
    int index, {
    Duration? duration,
    Curve? curve,
    bool animated = true,
  }) async {
    if (_pageCount > 0 && (index < 0 || index >= _pageCount)) return;
    if (index == _currentPage && !_isAnimating) return;

    if (animated && animateToPageDelegate != null) {
      await animateToPageDelegate!(index, duration: duration, curve: curve);
    } else if (jumpToPageDelegate != null) {
      jumpToPageDelegate!(index);
    } else {
      onNavigate?.call(index);
    }
  }

  /// Navigates to the next page.
  Future<void> nextPage({Duration? duration, Curve? curve}) async {
    final next = _currentPage + 1;
    if (_pageCount > 0 && next >= _pageCount) return;
    await goToPage(next, duration: duration, curve: curve);
  }

  /// Navigates to the previous page.
  Future<void> previousPage({Duration? duration, Curve? curve}) async {
    final prev = _currentPage - 1;
    if (prev < 0) return;
    await goToPage(prev, duration: duration, curve: curve);
  }

  /// Called when an inner page scrollable overscrolls past its boundaries.
  ///
  /// - [atEnd]: true when overscrolling past the bottom/end of the page content.
  /// - [overscrollDelta]: raw overscroll pixel displacement.
  void handleInnerOverscroll({
    required bool atEnd,
    required double overscrollDelta,
    required double velocity,
  }) {
    if (_isAnimating) return;

    const overscrollThreshold = 48.0;
    const velocityThreshold = 400.0;

    if (atEnd) {
      // User scrolled to the very bottom and pulled up further
      if (overscrollDelta > overscrollThreshold || velocity < -velocityThreshold) {
        nextPage();
      }
    } else {
      // User scrolled to the very top and pulled down further
      if (overscrollDelta < -overscrollThreshold || velocity > velocityThreshold) {
        previousPage();
      }
    }
  }

  @override
  void dispose() {
    animateToPageDelegate = null;
    jumpToPageDelegate = null;
    onNavigate = null;
    super.dispose();
  }
}
