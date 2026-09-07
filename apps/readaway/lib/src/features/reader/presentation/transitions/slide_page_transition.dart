import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Classic 1:1 side-by-side push conveyor page transition.
///
/// Pages move in unison pinned edge-to-edge as in standard e-readers and carousels.
class SlidePageTransitionStrategy extends ReaderPageTransitionStrategy {
  const SlidePageTransitionStrategy({
    this.showShadow = true,
  });

  /// Whether to render a subtle boundary shadow on the incoming page edge.
  final bool showShadow;

  @override
  Widget buildTransition({
    required BuildContext context,
    required Widget outgoingPage,
    required Widget incomingPage,
    required double progress,
    required PageTransitionMetrics metrics,
  }) {
    final t = progress.clamp(0.0, 1.0);
    final sign = metrics.isForward ? 1.0 : -1.0;
    final isHorizontal = metrics.isHorizontal;

    // Incoming translation: starts at sign * 1.0 and moves to 0.0
    final incomingOffset = isHorizontal
        ? Offset(sign * (1.0 - t), 0)
        : Offset(0, sign * (1.0 - t));

    // Outgoing translation: full 1:1 push from 0.0 to -sign * 1.0 (side-by-side conveyor)
    final outgoingOffset = isHorizontal
        ? Offset(-sign * t, 0)
        : Offset(0, -sign * t);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Outgoing page layer (pushes off)
        FractionalTranslation(
          translation: outgoingOffset,
          child: outgoingPage,
        ),

        // Incoming page layer (on top, slides in)
        FractionalTranslation(
          translation: incomingOffset,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showShadow && t < 1.0)
                Positioned(
                  left: isHorizontal ? (metrics.isForward ? -24 : null) : 0,
                  right: isHorizontal ? (!metrics.isForward ? -24 : null) : 0,
                  top: !isHorizontal ? (metrics.isForward ? -24 : null) : 0,
                  bottom: !isHorizontal ? (!metrics.isForward ? -24 : null) : 0,
                  width: isHorizontal ? 24 : null,
                  height: !isHorizontal ? 24 : null,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isHorizontal
                            ? LinearGradient(
                                begin: metrics.isForward
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                end: metrics.isForward
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.18),
                                ],
                              )
                            : LinearGradient(
                                begin: metrics.isForward
                                    ? Alignment.topCenter
                                    : Alignment.bottomCenter,
                                end: metrics.isForward
                                    ? Alignment.bottomCenter
                                    : Alignment.topCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.18),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              incomingPage,
            ],
          ),
        ),
      ],
    );
  }
}
