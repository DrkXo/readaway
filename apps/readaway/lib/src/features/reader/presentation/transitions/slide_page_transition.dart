import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Smooth sliding page transition with edge shadow and outgoing parallax.
class SlidePageTransitionStrategy extends ReaderPageTransitionStrategy {
  const SlidePageTransitionStrategy({
    this.parallaxFactor = 0.25,
    this.showShadow = true,
    this.showScrim = true,
  });

  /// Parallax speed factor for the outgoing page (0.0 = static, 1.0 = moves with incoming).
  final double parallaxFactor;

  /// Whether to render an elevation shadow on the incoming page edge.
  final bool showShadow;

  /// Whether to dim the outgoing page as it recedes.
  final double scrimMaxOpacity = 0.2;
  final bool showScrim;

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

    // Outgoing translation: starts at 0.0 and recedes with parallax to -sign * parallaxFactor
    final outgoingOffset = isHorizontal
        ? Offset(-sign * t * parallaxFactor, 0)
        : Offset(0, -sign * t * parallaxFactor);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Outgoing page layer (underneath)
        FractionalTranslation(
          translation: outgoingOffset,
          child: Stack(
            fit: StackFit.expand,
            children: [
              outgoingPage,
              if (showScrim && t > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: (t * scrimMaxOpacity).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
