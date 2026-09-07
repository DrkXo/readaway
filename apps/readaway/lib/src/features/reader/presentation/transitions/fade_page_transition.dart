import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Directional soft-gradient dissolve page transition.
///
/// Sweeps a smooth dissolve wave across the page from the direction of navigation,
/// creating an elegant and modern page-turn dissolve instead of a flat whole-page fade.
class FadePageTransitionStrategy extends ReaderPageTransitionStrategy {
  const FadePageTransitionStrategy({
    this.featherWidth,
  });

  /// The relative width of the soft dissolve gradient feather (0.1 = sharp wave, 0.5 = wide soft wave).
  final double? featherWidth;

  @override
  Widget buildTransition({
    required BuildContext context,
    required Widget outgoingPage,
    required Widget incomingPage,
    required double progress,
    required PageTransitionMetrics metrics,
  }) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.0) return outgoingPage;
    if (t >= 1.0) return incomingPage;

    final isHorizontal = metrics.isHorizontal;
    final isForward = metrics.isForward;

    // Direction of the dissolve wave:
    // Forward (next page): sweeps from trailing edge (right in horizontal LTR) to leading edge (left)
    // Backward (previous page): sweeps from leading edge (left) to trailing edge (right)
    final beginAlignment = isHorizontal
        ? (isForward ? Alignment.centerRight : Alignment.centerLeft)
        : (isForward ? Alignment.bottomCenter : Alignment.topCenter);

    final endAlignment = isHorizontal
        ? (isForward ? Alignment.centerLeft : Alignment.centerRight)
        : (isForward ? Alignment.topCenter : Alignment.bottomCenter);

    final effectiveFeather = (featherWidth ?? 0.35).clamp(0.05, 0.8);
    final p2 = (t * (1.0 + effectiveFeather)).clamp(0.0, 1.0);
    final p1 = (p2 - effectiveFeather).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Outgoing page remains fully rendered beneath
        outgoingPage,

        // Incoming page dissolves in from the navigation direction via soft gradient mask
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: beginAlignment,
              end: endAlignment,
              stops: [0.0, p1, p2, 1.0],
              colors: const [
                Colors.white,
                Colors.white,
                Colors.transparent,
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: incomingPage,
        ),
      ],
    );
  }
}
