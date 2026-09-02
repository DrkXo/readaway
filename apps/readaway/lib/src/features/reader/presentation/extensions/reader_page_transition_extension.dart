import 'package:flutter/widgets.dart';

import '../../../settings/domain/models/reader_preferences.dart';

/// Extension on [ReaderPageTransition] to apply page transitions.
extension ReaderPageTransitionX on ReaderPageTransition {
  Widget applyTransition(
    Widget child,
    double t, {
    required bool outgoing,
    required bool horizontal,
    required bool goingForward,
  }) {
    final sign = goingForward ? 1.0 : -1.0;

    switch (this) {
      case ReaderPageTransition.none:
        return child;

      case ReaderPageTransition.fade:
        return Opacity(opacity: outgoing ? (1 - t) : t, child: child);

      case ReaderPageTransition.slide:
        final offset = outgoing
            ? Offset(-sign * t, 0)
            : Offset(sign * (1 - t), 0);
        final slideOffset = horizontal ? offset : Offset(offset.dy, offset.dx);
        return FractionalTranslation(
          translation: slideOffset,
          child: child,
        );

      case ReaderPageTransition.sharedAxis:
        final offset = outgoing
            ? Offset(-sign * t, 0)
            : Offset(sign * (1 - t), 0);
        final slideOffset = horizontal ? offset : Offset(offset.dy, offset.dx);
        final scale = outgoing ? (1 - 0.05 * t) : (0.95 + 0.05 * t);
        return Opacity(
          opacity: outgoing ? (1 - t) : t,
          child: Transform.scale(
            scale: scale,
            child: FractionalTranslation(
              translation: slideOffset,
              child: child,
            ),
          ),
        );
    }
  }
}
