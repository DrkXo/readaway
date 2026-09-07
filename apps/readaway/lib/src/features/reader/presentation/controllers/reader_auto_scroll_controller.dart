import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import '../../domain/gestures/reader_gesture_constants.dart';

/// Controller managing hands-free auto-scrolling for the reader viewport.
///
/// Supports:
/// - Smooth, frame-driven continuous vertical scrolling.
/// - Dynamic speed adjustments (px/second).
/// - Transient pausing during user interactions (drag, selection, pull-down).
class ReaderAutoScrollController extends ChangeNotifier {
  ReaderAutoScrollController({
    double initialSpeed = 40.0,
    ReaderGestureConstants? constants,
  }) : _speed = initialSpeed,
       _constants =
           constants ??
           (GetIt.I.isRegistered<ReaderGestureConstants>()
               ? GetIt.I<ReaderGestureConstants>()
               : const ReaderGestureConstants());

  double _speed;
  final ReaderGestureConstants _constants;
  bool _isActive = false;
  bool _isPaused = false;

  Ticker? _ticker;
  Duration _lastTimestamp = Duration.zero;
  ScrollController? _attachedScrollController;

  /// Current scroll speed in pixels per second.
  double get speed => _speed;

  /// Whether auto-scrolling is currently running.
  bool get isActive => _isActive;

  /// Whether auto-scrolling is temporarily paused due to touch interaction.
  bool get isPaused => _isPaused;

  /// Attaches a [ScrollController] for continuous vertical scrolling.
  void attachScrollController(ScrollController scrollController) {
    _attachedScrollController = scrollController;
  }

  /// Detaches the scroll controller.
  void detachScrollController() {
    _attachedScrollController = null;
    stop();
  }

  /// Sets speed with clamping to bounds.
  void setSpeed(double newSpeed) {
    final clamped = newSpeed.clamp(
      _constants.minAutoScrollSpeed,
      _constants.maxAutoScrollSpeed,
    );
    if (_speed == clamped) return;
    _speed = clamped;
    notifyListeners();
  }

  /// Starts or resumes auto-scrolling using a [TickerProvider].
  void start(TickerProvider vsync) {
    if (_isActive && !_isPaused) return;

    _isActive = true;
    _isPaused = false;
    _lastTimestamp = Duration.zero;

    _ticker?.dispose();
    _ticker = vsync.createTicker(_onTick)..start();
    notifyListeners();
  }

  /// Stops auto-scrolling and disposes the ticker.
  void stop() {
    if (!_isActive) return;
    _isActive = false;
    _isPaused = false;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    notifyListeners();
  }

  /// Toggles between started and stopped.
  void toggle(TickerProvider vsync) {
    if (_isActive) {
      stop();
    } else {
      start(vsync);
    }
  }

  /// Temporarily pauses scrolling during user touches.
  void pause() {
    if (!_isActive || _isPaused) return;
    _isPaused = true;
    _ticker?.muted = true;
    notifyListeners();
  }

  /// Resumes scrolling after user touches finish.
  void resume() {
    if (!_isActive || !_isPaused) return;
    _isPaused = false;
    _lastTimestamp = Duration.zero;
    _ticker?.muted = false;
    notifyListeners();
  }

  void _onTick(Duration timestamp) {
    if (!_isActive || _isPaused) return;

    if (_lastTimestamp == Duration.zero) {
      _lastTimestamp = timestamp;
      return;
    }

    final dtSeconds = (timestamp - _lastTimestamp).inMicroseconds / 1000000.0;
    _lastTimestamp = timestamp;

    if (dtSeconds <= 0 || dtSeconds > 0.1) return; // ignore frame drops/janks

    final deltaPx = _speed * dtSeconds;

    final sc = _attachedScrollController;
    if (sc != null && sc.hasClients) {
      final current = sc.offset;
      final max = sc.position.maxScrollExtent;
      if (current >= max) {
        stop(); // reached the end of document
        return;
      }
      sc.jumpTo((current + deltaPx).clamp(0.0, max));
    }
  }

  @override
  void dispose() {
    stop();
    _attachedScrollController = null;
    super.dispose();
  }
}
