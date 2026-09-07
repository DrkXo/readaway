import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/gestures/reader_gestures.dart';

enum _ClaimedGesture {
  none,
  autoScrollSpeed,
  pageDrag,
}

/// A coordinated gesture arena that resolves and arbitrates touch gestures
/// over the reader viewport with zero ambiguity and priority-based ownership.
///
/// Priority Order:
/// 1. Multi-touch (pinch-to-zoom) -> immediately yields and cancels single-touch gestures.
/// 2. Right-edge vertical swipe -> Auto-scroll speed HUD (when enabled).
/// 3. Horizontal/Vertical page drag -> Interactive 1:1 page turning.
/// 4. Tap -> 3-zone tap actions (Prev, Chrome toggle, Next).
class ReaderGestureArena extends StatefulWidget {
  /// Timestamp of the last tap handled by an inner widget (e.g. link).
  static DateTime _lastSuppressedTapTime = DateTime.fromMillisecondsSinceEpoch(
    0,
  );

  /// Call this when an inner widget (such as a link) handles a tap,
  /// suppressing the arena's own tap action (chrome toggle / page turn).
  static void suppressNextTap() {
    _lastSuppressedTapTime = DateTime.now();
  }

  /// Whether a tap was recently handled by an inner child.
  static bool get isTapSuppressed =>
      DateTime.now().difference(_lastSuppressedTapTime).inMilliseconds < 450;

  ReaderGestureArena({
    super.key,
    required this.child,
    required this.onTapAction,
    this.onSpeedChange,
    this.currentSpeed = 50.0,
    this.autoScrollActive = false,
    this.onPageDragStart,
    this.onPageDragUpdate,
    this.onPageDragEnd,
    this.onPageDragCancel,
    this.isVerticalPaging = false,
    this.isRtl = false,
    this.swapClickArea = false,
    this.enabled = true,
    this.isAtScrollBoundary,
    ReaderGestureConstants? constants,
    EdgeSwipePolicy? edgeSwipePolicy,
    TapZonePolicy? tapZonePolicy,
  }) : constants =
           constants ??
           (GetIt.I.isRegistered<ReaderGestureConstants>()
               ? GetIt.I<ReaderGestureConstants>()
               : const ReaderGestureConstants()),
       edgeSwipePolicy =
           edgeSwipePolicy ??
           (GetIt.I.isRegistered<EdgeSwipePolicy>()
               ? GetIt.I<EdgeSwipePolicy>()
               : const EdgeSwipePolicy()),
       tapZonePolicy =
           tapZonePolicy ??
           (GetIt.I.isRegistered<TapZonePolicy>()
               ? GetIt.I<TapZonePolicy>()
               : const TapZonePolicy());

  final Widget child;

  /// Triggered on single tap with the resolved [ReaderTapAction].
  final ValueChanged<ReaderTapAction> onTapAction;

  /// Auto-scroll speed callbacks.
  final ValueChanged<double>? onSpeedChange;
  final double currentSpeed;
  final bool autoScrollActive;

  /// Page drag callbacks for interactive transitions.
  final VoidCallback? onPageDragStart;
  final void Function(double primaryDelta, double normalizedDelta)?
  onPageDragUpdate;
  final void Function(double velocity)? onPageDragEnd;
  final VoidCallback? onPageDragCancel;

  /// Paging configuration.
  final bool isVerticalPaging;
  final bool isRtl;
  final bool swapClickArea;
  final bool enabled;

  /// In vertical paging mode, called before claiming a vertical page drag.
  ///
  /// Receives `atEnd: true` when the drag is forward (down/next), `false` when backward (up/prev).
  /// Return `true` if the current page's scroll view is at its boundary in that direction
  /// (meaning the arena should claim the drag and flip the page).
  /// Return `false` to let the inner scroll view handle the event instead.
  ///
  /// If omitted, the arena always claims vertical drags in vertical paging mode.
  final bool Function(bool atEnd)? isAtScrollBoundary;

  /// Injected gesture policies.
  final ReaderGestureConstants constants;
  final EdgeSwipePolicy edgeSwipePolicy;
  final TapZonePolicy tapZonePolicy;

  @override
  State<ReaderGestureArena> createState() => _ReaderGestureArenaState();
}

class _ReaderGestureArenaState extends State<ReaderGestureArena> {
  final Map<int, PointerDownEvent> _activePointers = {};

  _ClaimedGesture _claimed = _ClaimedGesture.none;

  // Gesture state for the tracking pointer
  int? _trackingPointerId;
  Offset _startPosition = Offset.zero;
  DateTime _startTime = DateTime.now();
  double _startSpeed = 50.0;
  double _lastSpeed = 50.0;
  double _lastPrimaryPos = 0.0;
  DateTime _lastMoveTime = DateTime.now();
  double _lastVelocity = 0.0;

  bool _armedRightEdge = false;

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;

    _activePointers[event.pointer] = event;

    // A second finger immediately cancels any armed or active single-touch gesture
    // so multi-finger gestures (pinch/zoom) have uninhibited control.
    if (_activePointers.length > 1) {
      _abortCurrentGesture();
      return;
    }

    _trackingPointerId = event.pointer;
    _startPosition = event.localPosition;
    _lastPrimaryPos = widget.isVerticalPaging
        ? event.localPosition.dy
        : event.localPosition.dx;
    _startTime = DateTime.now();
    _lastMoveTime = _startTime;
    _lastVelocity = 0.0;

    _startSpeed = widget.currentSpeed;
    _lastSpeed = widget.currentSpeed;
    _claimed = _ClaimedGesture.none;

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    if (size.width <= 0 || size.height <= 0) return;

    // Check right edge arming for auto-scroll speed
    _armedRightEdge =
        widget.autoScrollActive &&
        widget.edgeSwipePolicy.isInRightEdge(
          event.localPosition.dx,
          size.width,
        );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _trackingPointerId || _activePointers.length != 1) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    if (size.width <= 0 || size.height <= 0) return;

    final deltaX = event.localPosition.dx - _startPosition.dx;
    final deltaY = event.localPosition.dy - _startPosition.dy;
    final currentPrimary = widget.isVerticalPaging
        ? event.localPosition.dy
        : event.localPosition.dx;
    final primaryStep = currentPrimary - _lastPrimaryPos;
    _lastPrimaryPos = currentPrimary;

    // Calculate instantaneous velocity
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastMoveTime).inMilliseconds;
    if (elapsedMs > 0) {
      _lastVelocity = primaryStep / (elapsedMs / 1000.0);
    }
    _lastMoveTime = now;

    // 1. If Auto-scroll Speed is claimed
    if (_claimed == _ClaimedGesture.autoScrollSpeed) {
      final s = widget.edgeSwipePolicy.computeAutoScrollSpeed(
        _startSpeed,
        deltaY,
        size.height,
      );
      _lastSpeed = s;
      widget.onSpeedChange?.call(s);
      return;
    }

    // 2. If Page Drag is claimed
    if (_claimed == _ClaimedGesture.pageDrag) {
      final dimension = widget.isVerticalPaging ? size.height : size.width;
      final normalizedDelta = -primaryStep / (dimension > 0 ? dimension : 1.0);
      widget.onPageDragUpdate?.call(primaryStep, normalizedDelta);
      return;
    }

    // --- ARBITRATION (No gesture claimed yet) ---

    // A. Check Right Edge Speed activation
    if (_armedRightEdge &&
        widget.edgeSwipePolicy.shouldActivateEdgeGesture(deltaX, deltaY)) {
      _claimed = _ClaimedGesture.autoScrollSpeed;
      final s = widget.edgeSwipePolicy.computeAutoScrollSpeed(
        _startSpeed,
        deltaY,
        size.height,
      );
      _lastSpeed = s;
      widget.onSpeedChange?.call(s);
      return;
    }

    // B. Check Page Drag activation
    final primaryDelta = widget.isVerticalPaging ? deltaY : deltaX;
    final crossDelta = widget.isVerticalPaging ? deltaX : deltaY;

    if (primaryDelta.abs() >= widget.constants.activationThresholdPx &&
        primaryDelta.abs() >
            crossDelta.abs() * widget.constants.directionDominanceMultiplier) {
      // In vertical paging mode, only claim when the inner scroll view is already
      // at its boundary in the drag direction. A negative primaryDelta (drag upward)
      // means going forward (atEnd = true); positive means going backward (atEnd = false).
      if (widget.isVerticalPaging && widget.isAtScrollBoundary != null) {
        final atEnd = primaryDelta < 0; // dragging up = next page
        if (!widget.isAtScrollBoundary!(atEnd)) {
          // Inner scroll view is not at its edge — let it handle the gesture.
          return;
        }
      }

      _claimed = _ClaimedGesture.pageDrag;
      widget.onPageDragStart?.call();
      final dimension = widget.isVerticalPaging ? size.height : size.width;
      final normalizedDelta = -primaryDelta / (dimension > 0 ? dimension : 1.0);
      widget.onPageDragUpdate?.call(primaryDelta, normalizedDelta);
      return;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    if (event.pointer != _trackingPointerId) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    switch (_claimed) {
      case _ClaimedGesture.autoScrollSpeed:
        widget.onSpeedChange?.call(_lastSpeed);
        break;
      case _ClaimedGesture.pageDrag:
        widget.onPageDragEnd?.call(_lastVelocity);
        break;
      case _ClaimedGesture.none:
        // No drag or edge gesture claimed -> evaluate tap
        final deltaX = (event.localPosition.dx - _startPosition.dx).abs();
        final deltaY = (event.localPosition.dy - _startPosition.dy).abs();
        final elapsed = DateTime.now().difference(_startTime).inMilliseconds;

        if (deltaX < 18.0 && deltaY < 18.0 && elapsed < 400 && size.width > 0) {
          final localX = event.localPosition.dx;
          final width = size.width;
          // Defer to microtask so inner recognizers (like link taps in TextSpan)
          // running during pointer resolution can claim the tap and suppress arena action.
          scheduleMicrotask(() {
            if (!mounted) return;
            if (ReaderGestureArena.isTapSuppressed) return;

            final action = widget.tapZonePolicy.resolveTapAction(
              localX,
              width,
              isRtl: widget.isRtl,
              swapClickArea: widget.swapClickArea,
            );
            widget.onTapAction(action);
          });
        }
        break;
    }

    _resetGesture();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (event.pointer == _trackingPointerId) {
      _abortCurrentGesture();
    }
  }

  void _abortCurrentGesture() {
    switch (_claimed) {
      case _ClaimedGesture.pageDrag:
        widget.onPageDragCancel?.call();
        break;
      default:
        break;
    }
    _resetGesture();
  }

  void _resetGesture() {
    _trackingPointerId = null;
    _claimed = _ClaimedGesture.none;
    _armedRightEdge = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
