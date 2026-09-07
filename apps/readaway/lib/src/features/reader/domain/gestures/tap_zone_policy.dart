import 'package:injectable/injectable.dart';

import 'reader_gesture_constants.dart';

/// Actions resolved from reader tap zones.
enum ReaderTapAction {
  previousPage,
  toggleChrome,
  nextPage,
}

/// Pure policy for resolving tap locations into reader actions.
@lazySingleton
class TapZonePolicy {
  const TapZonePolicy({
    this.constants = const ReaderGestureConstants(),
  });

  final ReaderGestureConstants constants;

  /// Resolves the tap action given an [x] coordinate and [viewWidth].
  ReaderTapAction resolveTapAction(
    double x,
    double viewWidth, {
    bool isRtl = false,
    bool swapClickArea = false,
  }) {
    if (viewWidth <= 0) return ReaderTapAction.toggleChrome;

    final ratio = x / viewWidth;

    if (ratio < constants.leftTapZoneEndRatio) {
      final isPrev = (!isRtl && !swapClickArea) || (isRtl && swapClickArea);
      return isPrev ? ReaderTapAction.previousPage : ReaderTapAction.nextPage;
    } else if (ratio > constants.rightTapZoneStartRatio) {
      final isNext = (!isRtl && !swapClickArea) || (isRtl && swapClickArea);
      return isNext ? ReaderTapAction.nextPage : ReaderTapAction.previousPage;
    } else {
      return ReaderTapAction.toggleChrome;
    }
  }
}
