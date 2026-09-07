import 'package:injectable/injectable.dart';

import 'reader_gesture_constants.dart';

/// Pure math and detection policy for edge gestures (auto-scroll speed).
@lazySingleton
class EdgeSwipePolicy {
  const EdgeSwipePolicy({
    this.constants = const ReaderGestureConstants(),
  });

  final ReaderGestureConstants constants;

  /// Checks if an x-coordinate falls inside the right edge boundary.
  bool isInRightEdge(
    double x,
    double viewWidth, {
    double? ratio,
  }) {
    if (viewWidth <= 0) return false;
    final r = ratio ?? constants.edgeZoneRatio;
    return x >= viewWidth * (1.0 - r) && x <= viewWidth;
  }

  /// True when movement along the edge is vertical-dominant past activation threshold.
  bool shouldActivateEdgeGesture(
    double deltaX,
    double deltaY, {
    double? threshold,
  }) {
    final t = threshold ?? constants.activationThresholdPx;
    final absX = deltaX.abs();
    final absY = deltaY.abs();
    return absY >= t && absY > absX * constants.directionDominanceMultiplier;
  }

  /// Computes updated auto-scroll speed based on vertical finger drag.
  /// Swiping up (negative deltaY) increases speed; swiping down decreases it.
  double computeAutoScrollSpeed(
    double startSpeed,
    double deltaY,
    double viewHeight,
  ) {
    if (viewHeight <= 0) return startSpeed;
    final totalRange =
        constants.maxAutoScrollSpeed - constants.minAutoScrollSpeed;
    final change = (-deltaY / viewHeight) * totalRange;
    final raw = (startSpeed + change).clamp(
      constants.minAutoScrollSpeed,
      constants.maxAutoScrollSpeed,
    );
    // Snap to step increment
    final step = constants.autoScrollSpeedStep;
    return ((raw / step).round() * step).clamp(
      constants.minAutoScrollSpeed,
      constants.maxAutoScrollSpeed,
    );
  }
}
