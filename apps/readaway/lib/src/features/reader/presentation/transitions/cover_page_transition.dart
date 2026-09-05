import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Cover / Reveal transition: the incoming page slides smoothly over the outgoing page
/// like turning a sheet of printed paper, with an elevation edge shadow.
class CoverPageTransitionStrategy extends ReaderPageTransitionStrategy {
  const CoverPageTransitionStrategy({
    this.elevation = 16.0,
    this.dimBackground = true,
  });

  final double elevation;
  final bool dimBackground;

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

    // Incoming page offset from 1.0 to 0.0
    final incomingOffset = isHorizontal
        ? Offset(sign * (1.0 - t), 0)
        : Offset(0, sign * (1.0 - t));

    return Stack(
      fit: StackFit.expand,
      children: [
        // Outgoing page remains stationary beneath
        Stack(
          fit: StackFit.expand,
          children: [
            outgoingPage,
            if (dimBackground && t > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: (t * 0.15).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Incoming page slides over
        FractionalTranslation(
          translation: incomingOffset,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (t < 1.0)
                Positioned(
                  left: isHorizontal ? (metrics.isForward ? -elevation : null) : 0,
                  right: isHorizontal ? (!metrics.isForward ? -elevation : null) : 0,
                  top: !isHorizontal ? (metrics.isForward ? -elevation : null) : 0,
                  bottom: !isHorizontal ? (!metrics.isForward ? -elevation : null) : 0,
                  width: isHorizontal ? elevation : null,
                  height: !isHorizontal ? elevation : null,
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
                                  Colors.black.withValues(alpha: 0.22),
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
                                  Colors.black.withValues(alpha: 0.22),
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
