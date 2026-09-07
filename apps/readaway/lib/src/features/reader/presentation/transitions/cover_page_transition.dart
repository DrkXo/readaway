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
    final isHorizontal = metrics.isHorizontal;
    final isForward = metrics.isForward;

    Widget buildElevationShadow() {
      return Positioned(
        left: isHorizontal ? -elevation : 0,
        top: !isHorizontal ? -elevation : 0,
        right: isHorizontal ? null : 0,
        bottom: !isHorizontal ? null : 0,
        width: isHorizontal ? elevation : null,
        height: !isHorizontal ? elevation : null,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isHorizontal
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    if (isForward) {
      // Forward: Incoming page slides IN on top, covering the stationary outgoing page
      final incomingOffset = isHorizontal
          ? Offset(1.0 - t, 0)
          : Offset(0, 1.0 - t);

      return Stack(
        fit: StackFit.expand,
        children: [
          // Outgoing stationary page beneath
          Stack(
            fit: StackFit.expand,
            children: [
              outgoingPage,
              if (dimBackground && t > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: (t * 0.18).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Incoming sheet slides in over outgoing
          FractionalTranslation(
            translation: incomingOffset,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (t < 1.0) buildElevationShadow(),
                incomingPage,
              ],
            ),
          ),
        ],
      );
    } else {
      // Backward: Outgoing page slides OUT on top to reveal the stationary incoming page beneath
      final outgoingOffset = isHorizontal ? Offset(t, 0) : Offset(0, t);

      return Stack(
        fit: StackFit.expand,
        children: [
          // Incoming page waiting stationary beneath
          Stack(
            fit: StackFit.expand,
            children: [
              incomingPage,
              if (dimBackground && t < 1.0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: ((1.0 - t) * 0.18).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Outgoing sheet slides away to reveal the incoming page
          FractionalTranslation(
            translation: outgoingOffset,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (t < 1.0) buildElevationShadow(),
                outgoingPage,
              ],
            ),
          ),
        ],
      );
    }
  }
}
