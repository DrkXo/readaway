import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Material 3 Shared Axis page transition: directional fade-through with subtle offset and scale.
class SharedAxisPageTransitionStrategy extends ReaderPageTransitionStrategy {
  const SharedAxisPageTransitionStrategy({
    this.translationDistance,
  });

  /// The subtle translation distance in logical pixels along the transition axis.
  final double? translationDistance;

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
    final distance = translationDistance ?? 48.0;

    // Outgoing parameters: shifts slightly back (-sign * distance * t), scales 1.0 -> 0.94, fades out over [0.0, 0.38]
    final outgoingTranslation = -sign * distance * t;
    final outgoingOffset = isHorizontal
        ? Offset(outgoingTranslation, 0)
        : Offset(0, outgoingTranslation);
    final outgoingScale = 1.0 - (0.06 * t);
    final outgoingOpacity = (1.0 - (t / 0.38)).clamp(0.0, 1.0);

    // Incoming parameters: shifts into place from (sign * distance * (1.0 - t)), scales 0.94 -> 1.0, fades in over [0.22, 1.0]
    final incomingTranslation = sign * distance * (1.0 - t);
    final incomingOffset = isHorizontal
        ? Offset(incomingTranslation, 0)
        : Offset(0, incomingTranslation);
    final incomingScale = 0.94 + (0.06 * t);
    final incomingOpacity = ((t - 0.22) / 0.78).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (outgoingOpacity > 0.0)
          Opacity(
            opacity: outgoingOpacity,
            child: Transform.scale(
              scale: outgoingScale,
              child: Transform.translate(
                offset: outgoingOffset,
                child: outgoingPage,
              ),
            ),
          ),
        if (incomingOpacity > 0.0)
          Opacity(
            opacity: incomingOpacity,
            child: Transform.scale(
              scale: incomingScale,
              child: Transform.translate(
                offset: incomingOffset,
                child: incomingPage,
              ),
            ),
          ),
      ],
    );
  }
}
