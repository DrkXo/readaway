import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Drives smooth, frame-synced auto-scrolling through a reflowable reader.
///
/// The controller scrolls the *current* page's vertical [ScrollController]
/// at a rate derived from the configured speed, and when the page's content
/// is exhausted it flips to the next page via [goToNextPage].
///
/// Design notes (production-grade):
///  * Uses a [Ticker] (not a raw `Timer`) so scrolling is tied to the frame
///    cadence — smooth on 60/120 Hz displays and it automatically stops
///    producing work when frames aren't being rendered.
///  * The ticker is only active while running **and** the app is in the
///    foreground, so it never burns CPU in the background.
///  * Per-page [ScrollController]s are registered/unregistered as pages
///    mount/unmount, so we never hold stale references.
class AutoScrollController extends ChangeNotifier {
  AutoScrollController({
    required TickerProvider vsync,
    required this.goToNextPage,
    this.basePixelsPerSecond = 20,
  }) {
    _ticker = vsync.createTicker(_onTick);
  }

  /// Base scroll rate for `speed == 1`. Actual rate is `speed * base`.
  final double basePixelsPerSecond;

  /// Called to advance to the next page when the current page's content is
  /// exhausted. The owner wires this to the reader's page navigation.
  final VoidCallback goToNextPage;

  late final Ticker _ticker;

  /// Page index -> its vertical scroll controller.
  final Map<int, ScrollController> _pageControllers = {};

  int _currentPage = 0;
  int _speed = 1;
  int _pageCount = 0;
  bool _running = false;
  bool _paused = false;
  bool _flipping = false;
  Duration _lastElapsed = Duration.zero;
  double _shortPageDwellAccumulator = 0.0;

  /// Whether auto-scroll is currently active (running and not paused).
  bool get isActive => _running && !_paused;

  /// Whether the user has enabled auto-scroll.
  bool get isRunning => _running;

  /// Current configured speed (1–5).
  int get speed => _speed;

  /// Pixels scrolled per second at the current speed.
  double get pixelsPerSecond => _speed * basePixelsPerSecond;

  /// Registers the [ScrollController] backing the page at [index].
  void registerPage(int index, ScrollController controller) {
    _pageControllers[index] = controller;
  }

  /// Removes the [ScrollController] for the page at [index].
  void unregisterPage(int index) {
    _pageControllers.remove(index);
  }

  /// Updates the total number of pages (used to stop at the end of the book).
  void setPageCount(int pageCount) {
    _pageCount = pageCount;
  }

  /// Updates the currently visible page index.
  void setCurrentPage(int index) {
    _currentPage = index;
    _flipping = false;
    _shortPageDwellAccumulator = 0.0;
    // Reset the elapsed baseline so the first tick after a page change
    // doesn't produce a large delta.
    _lastElapsed = Duration.zero;
  }

  /// Starts auto-scrolling at the current speed.
  void start() {
    if (_running) return;
    _running = true;
    _lastElapsed = Duration.zero;
    _maybeStartTicker();
    notifyListeners();
  }

  /// Stops auto-scrolling entirely.
  void stop() {
    if (!_running) return;
    _running = false;
    _flipping = false;
    _ticker.stop();
    notifyListeners();
  }

  /// Updates the scroll speed (clamped to 1–5).
  void setSpeed(int speed) {
    final clamped = speed.clamp(1, 5);
    if (_speed == clamped) return;
    _speed = clamped;
    notifyListeners();
  }

  /// Pauses scrolling (e.g. when the app goes to the background).
  void pause() {
    if (_paused) return;
    _paused = true;
    _ticker.stop();
    notifyListeners();
  }

  /// Resumes scrolling after [pause] if it was running.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _lastElapsed = Duration.zero;
    _maybeStartTicker();
    notifyListeners();
  }

  void _maybeStartTicker() {
    if (_running && !_paused && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!isActive || _flipping) return;

    final dt = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final controller = _pageControllers[_currentPage];
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;
    final maxExtent = position.maxScrollExtent;
    final current = position.pixels;
    final delta = pixelsPerSecond * dt;

    // Content shorter than the viewport: dwell before flipping.
    if (maxExtent <= 0) {
      final targetDwell = (6.0 - _speed).clamp(1.5, 6.0);
      _shortPageDwellAccumulator += dt;
      if (_shortPageDwellAccumulator >= targetDwell) {
        _flipToNextPage();
      }
      return;
    }

    if (current + delta >= maxExtent) {
      controller.jumpTo(maxExtent);
      _flipToNextPage();
    } else {
      controller.jumpTo(current + delta);
    }
  }

  void _flipToNextPage() {
    if (_flipping) return;
    // Reached the end of the book: stop gracefully instead of looping.
    if (_pageCount > 0 && _currentPage >= _pageCount - 1) {
      stop();
      return;
    }
    _flipping = true;
    goToNextPage();
  }

  @override
  void dispose() {
    stop();
    _ticker.dispose();
    _pageControllers.clear();
    super.dispose();
  }
}
