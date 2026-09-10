import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../settings/domain/entity/reader_preferences.dart';
import '../../../controllers/reader_viewport_controller.dart';

class PagedTransitionController extends ChangeNotifier {
  PagedTransitionController({
    required TickerProvider vsync,
    required this._currentPage,
    required this._pageCount,
    required this._transition,
    required this._direction,
    required Duration duration,
    required this._viewportController,
    required this._onPageCommitted,
  }) : _defaultDuration = duration,
       animationController = AnimationController(
         vsync: vsync,
         duration: duration,
       ) {
    curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    animationController
      ..addListener(_onAnimationTick)
      ..addStatusListener(_onAnimationStatus);
  }

  final AnimationController animationController;
  late final CurvedAnimation curvedAnimation;
  final ReaderViewportController? _viewportController;
  final ValueChanged<int> _onPageCommitted;
  final Duration _defaultDuration;

  ReaderPageTransition _transition;
  ReaderScrollDirection _direction;
  int _pageCount;
  int _currentPage;
  int? _targetPage;
  bool _isForward = true;
  bool _isInteractive = false;
  double _rawDragProgress = 0.0;
  DateTime _lastPointerScrollTime = DateTime.fromMillisecondsSinceEpoch(0);

  int get currentPage => _currentPage;
  int? get targetPage => _targetPage;
  bool get isForward => _isForward;
  bool get isInteractive => _isInteractive;

  void updateConfiguration({
    required int pageCount,
    required ReaderPageTransition transition,
    required ReaderScrollDirection direction,
    required Duration duration,
  }) {
    _pageCount = pageCount;
    _transition = transition;
    _direction = direction;
    animationController.duration = duration;
  }

  void syncCurrentPage(int page) {
    if (page == _currentPage ||
        animationController.isAnimating ||
        _isInteractive) {
      return;
    }

    final isForward = page > _currentPage;
    if (_transition == ReaderPageTransition.none) {
      _currentPage = page;
      _targetPage = null;
      notifyListeners();
    } else {
      _startAnimation(from: _currentPage, to: page, forward: isForward);
    }
  }

  Future<void> animateToPage(
    int target, {
    Duration? duration,
    Curve? curve,
  }) async {
    if (target < 0 || target >= _pageCount) return;
    if (target == _currentPage && !animationController.isAnimating) return;

    if (_transition == ReaderPageTransition.none) {
      jumpToPage(target);
      return;
    }

    animationController.stop();
    _startAnimation(
      from: _currentPage,
      to: target,
      forward: target > _currentPage,
      customDuration: duration,
      customCurve: curve,
    );
  }

  void jumpToPage(int target) {
    if (target < 0 || target >= _pageCount) return;
    animationController.stop();
    _currentPage = target;
    _targetPage = null;
    _isInteractive = false;
    notifyListeners();
    _onPageCommitted(target);
  }

  void handleDragStart() {
    if (animationController.isAnimating) {
      animationController.stop();
    }
    _isInteractive = true;
    _rawDragProgress = 0.0;
    _viewportController?.setInteractionState(isDragging: true);
    notifyListeners();
  }

  void handleDragUpdate(double primaryDelta, double normalizedDelta) {
    if (_pageCount <= 1) return;

    _rawDragProgress += normalizedDelta;
    final targetForward = _rawDragProgress >= 0;
    final potentialTarget = targetForward ? _currentPage + 1 : _currentPage - 1;

    if (potentialTarget < 0 || potentialTarget >= _pageCount) {
      _rawDragProgress *= 0.85;
      return;
    }

    if (_targetPage != potentialTarget || _isForward != targetForward) {
      _isForward = targetForward;
      _targetPage = potentialTarget;
      notifyListeners();
    }

    final visualProgress = _rawDragProgress.abs().clamp(0.0, 1.0);
    animationController.value = visualProgress;
    _viewportController?.setInteractionState(dragProgress: visualProgress);
  }

  void handleDragEnd(double velocity) {
    if (!_isInteractive || _targetPage == null) {
      _isInteractive = false;
      return;
    }

    final currentProgress = animationController.value;
    final movingInTargetDirection =
        (_isForward && velocity < 0) || (!_isForward && velocity > 0);
    final isFling = movingInTargetDirection && velocity.abs() > 250.0;
    final commit = isFling || currentProgress >= 0.3;

    _curvedAnimToEaseOut();
    if (commit) {
      final remaining = (1.0 - currentProgress).clamp(0.05, 1.0);
      final durationMs = (_defaultDuration.inMilliseconds * remaining)
          .round()
          .clamp(100, 400);
      animationController.duration = Duration(milliseconds: durationMs);
      animationController.forward(from: currentProgress);
    } else {
      final durationMs = (_defaultDuration.inMilliseconds * currentProgress)
          .round()
          .clamp(80, 300);
      animationController.duration = Duration(milliseconds: durationMs);
      animationController.reverse(from: currentProgress);
    }
  }

  void handleDragCancel() {
    if (_isInteractive) {
      _curvedAnimToEaseOut();
      animationController.reverse(from: animationController.value);
    }
  }

  void handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final now = DateTime.now();
    if (now.difference(_lastPointerScrollTime).inMilliseconds < 350) return;

    final isVertical = _direction == ReaderScrollDirection.vertical;
    final delta = isVertical
        ? event.scrollDelta.dy
        : (event.scrollDelta.dx != 0
              ? event.scrollDelta.dx
              : event.scrollDelta.dy);

    if (delta.abs() <= 15) return;
    _lastPointerScrollTime = now;

    if (delta > 0 && _currentPage < _pageCount - 1) {
      animateToPage(_currentPage + 1);
    } else if (delta < 0 && _currentPage > 0) {
      animateToPage(_currentPage - 1);
    }
  }

  void _startAnimation({
    required int from,
    required int to,
    required bool forward,
    Duration? customDuration,
    Curve? customCurve,
  }) {
    _currentPage = from;
    _targetPage = to;
    _isForward = forward;
    _isInteractive = false;
    _curvedAnimTo(customCurve ?? Curves.easeOutCubic);
    animationController.duration = customDuration ?? _defaultDuration;
    notifyListeners();
    animationController.forward(from: 0.0);
  }

  void _curvedAnimTo(Curve curve) {
    curvedAnimation.curve = curve;
  }

  void _curvedAnimToEaseOut() {
    _curvedAnimTo(Curves.easeOutCubic);
  }

  void _onAnimationTick() {
    if (!_isInteractive) {
      _viewportController?.setInteractionState(
        isAnimating: animationController.isAnimating,
        dragProgress: curvedAnimation.value,
      );
    }
    notifyListeners();
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
      _currentPage = newPage;
      _targetPage = null;
      _isInteractive = false;
      _onPageCommitted(newPage);
    } else {
      _targetPage = null;
      _isInteractive = false;
    }
    animationController.value = 0.0;
    _viewportController?.setInteractionState(
      isAnimating: false,
      isDragging: false,
      dragProgress: 0.0,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    animationController
      ..removeListener(_onAnimationTick)
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    curvedAnimation.dispose();
    super.dispose();
  }
}
