import 'package:injectable/injectable.dart';

/// Gesture constants and thresholds for reader interactions.
@lazySingleton
class ReaderGestureConstants {
  const ReaderGestureConstants();

  // Activation and dominance
  double get activationThresholdPx => 18.0;
  double get directionDominanceMultiplier => 2.0;

  // Tap navigation zone boundaries (fraction of total width)
  double get leftTapZoneEndRatio => 0.30;
  double get rightTapZoneStartRatio => 0.70;

  // Overlay timings
  Duration get chromeAnimationDuration => const Duration(milliseconds: 250);
  Duration get springBackDuration => const Duration(milliseconds: 260);
}
