import 'package:flutter/foundation.dart';

/// Central navigation entry point for the reader's page view.
///
/// All page navigation (bottom bar, TOC, drawer, internal links, auto-scroll)
/// funnels through this controller. It tracks the current page index and
/// delegates actual navigation to [onNavigate], which the owning widget wires
/// up (typically to dispatch a `ReaderEvent.pageChanged` to the reader BLoC).
///
/// The reader BLoC remains the single source of truth for the current page;
/// this controller is a thin command/state facade so widgets don't depend on
/// a `PageController` or the page-view implementation details.
class ReaderPageViewController extends ChangeNotifier {
  int _currentPage = 0;

  /// The currently displayed page index.
  int get currentPage => _currentPage;

  /// Set by the owner to perform navigation (e.g. dispatch to the BLoC).
  /// Receives the target page index.
  void Function(int index)? onNavigate;

  /// Updates the current page index (called when the page actually changes).
  void setCurrentPage(int index) {
    if (_currentPage == index) return;
    _currentPage = index;
    notifyListeners();
  }

  /// Requests navigation to [index] (clamped by the caller).
  void goToPage(int index) => onNavigate?.call(index);

  /// Requests navigation to the next page.
  void nextPage() => onNavigate?.call(_currentPage + 1);

  /// Requests navigation to the previous page.
  void previousPage() => onNavigate?.call(_currentPage - 1);
}
