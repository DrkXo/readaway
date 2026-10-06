import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/gestures/reader_gestures.dart';

enum _ClaimedGesture {
  none,
  pageDrag,
}

/// A coordinated gesture arena that resolves and arbitrates touch gestures
/// over the reader viewport with zero ambiguity and priority-based ownership.
///
/// Priority Order:
/// 1. Multi-touch (pinch-to-zoom) -> immediately yields and cancels single-touch gestures.
/// 2. Horizontal/Vertical page drag -> Interactive 1:1 page turning.
/// 3. Tap -> 3-zone tap actions (Prev, Chrome toggle, Next).
class ReaderGestureArena extends StatefulWidget {
  ReaderGestureArena({
    super.key,
    required this.child,
    required this.onTapAction,
    this.onTapIntercept,
    this.onPageDragStart,
    this.onPageDragUpdate,
    this.onPageDragEnd,
    this.onPageDragCancel,
    this.canStartPageDrag,
    this.canHandleTapAction,
    this.isVerticalPaging = false,
    this.isRtl = false,
    this.swapClickArea = false,
    this.enabled = true,
    this.isAtScrollBoundary,
    ReaderGestureConstants? constants,
    TapZonePolicy? tapZonePolicy,
  }) : constants =
           constants ??
           (GetIt.I.isRegistered<ReaderGestureConstants>()
               ? GetIt.I<ReaderGestureConstants>()
               : const ReaderGestureConstants()),
       tapZonePolicy =
           tapZonePolicy ??
           (GetIt.I.isRegistered<TapZonePolicy>()
               ? GetIt.I<TapZonePolicy>()
               : const TapZonePolicy());

  final Widget child;

  /// Triggered on single tap with the resolved [ReaderTapAction].
  final ValueChanged<ReaderTapAction> onTapAction;

  /// Consulted with the tap position before the tap-zone action is applied.
  ///
  /// Return true to consume the tap. Set by the reader so a tap that lands on a
  /// painted annotation opens it instead of running a tap-zone action.
  final bool Function(Offset globalPosition)? onTapIntercept;

  /// Page drag callbacks for interactive transitions.
  final VoidCallback? onPageDragStart;
  final void Function(double primaryDelta, double normalizedDelta)?
  onPageDragUpdate;
  final void Function(double velocity)? onPageDragEnd;
  final VoidCallback? onPageDragCancel;

  /// Whether a pointer drag may be claimed for page navigation.
  final bool Function()? canStartPageDrag;

  /// Whether a pointer tap may trigger a reader tap-zone action.
  final bool Function()? canHandleTapAction;

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
  double _lastPrimaryPos = 0.0;
  DateTime _lastMoveTime = DateTime.now();
  double _lastVelocity = 0.0;

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
    _claimed = _ClaimedGesture.none;
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

    // If Page Drag is claimed
    if (_claimed == _ClaimedGesture.pageDrag) {
      final dimension = widget.isVerticalPaging ? size.height : size.width;
      final normalizedDelta = -primaryStep / (dimension > 0 ? dimension : 1.0);
      widget.onPageDragUpdate?.call(primaryStep, normalizedDelta);
      return;
    }

    // --- ARBITRATION (No gesture claimed yet) ---
    final primaryDelta = widget.isVerticalPaging ? deltaY : deltaX;
    final crossDelta = widget.isVerticalPaging ? deltaX : deltaY;

    // A pointer held still long enough to become a long press belongs to the
    // text-selection overlay, not to paging. This arena only ever sees raw
    // pointer movement, so without this guard, dragging to extend a selection
    // past the activation threshold turns the page mid-selection.
    //
    // The hold is the reader's own signal, and it is the same one the selection
    // overlay acts on: hold to select, swipe promptly to page.
    if (now.difference(_startTime) >= kLongPressTimeout) return;

    if (primaryDelta.abs() >= widget.constants.activationThresholdPx &&
        primaryDelta.abs() >
            crossDelta.abs() * widget.constants.directionDominanceMultiplier &&
        (widget.canStartPageDrag?.call() ?? true)) {
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

    switch (_claimed) {
      case _ClaimedGesture.pageDrag:
        widget.onPageDragEnd?.call(_lastVelocity);
        break;
      case _ClaimedGesture.none:
        break;
    }

    _resetGesture();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    if (!(widget.canHandleTapAction?.call() ?? true)) return;

    // A tap on a painted annotation belongs to the annotation, so it must not
    // also turn the page or toggle the chrome.
    if (widget.onTapIntercept?.call(details.globalPosition) ?? false) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 0.0;
    if (width <= 0.0) return;

    widget.onTapAction(
      widget.tapZonePolicy.resolveTapAction(
        details.localPosition.dx,
        width,
        isRtl: widget.isRtl,
        swapClickArea: widget.swapClickArea,
      ),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _onTapUp,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: widget.child,
      ),
    );
  }
}
