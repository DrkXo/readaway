import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Material 3 Shared Axis page transition: combined subtle translation, scale, and fade.
class SharedAxisPageTransitionStrategy extends ReaderPageTransitionStrategy {
  const SharedAxisPageTransitionStrategy();

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

    // Outgoing parameters: fades out and slightly scales up / slides away
    final outgoingOffset = isHorizontal
        ? Offset(-sign * t * 0.3, 0)
        : Offset(0, -sign * t * 0.3);
    final outgoingScale = 1.0 + (0.04 * t);
    final outgoingOpacity = (1.0 - (t * 1.5)).clamp(0.0, 1.0);

    // Incoming parameters: fades in, scales from 0.96 to 1.0, slides in from 0.3 offset
    final incomingOffset = isHorizontal
        ? Offset(sign * (1.0 - t) * 0.3, 0)
        : Offset(0, sign * (1.0 - t) * 0.3);
    final incomingScale = 0.96 + (0.04 * t);
    final incomingOpacity = ((t - 0.2) * 1.25).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (outgoingOpacity > 0.0)
          Opacity(
            opacity: outgoingOpacity,
            child: Transform.scale(
              scale: outgoingScale,
              child: FractionalTranslation(
                translation: outgoingOffset,
                child: outgoingPage,
              ),
            ),
          ),
        Opacity(
          opacity: incomingOpacity,
          child: Transform.scale(
            scale: incomingScale,
            child: FractionalTranslation(
              translation: incomingOffset,
              child: incomingPage,
            ),
          ),
        ),
      ],
    );
  }
}
