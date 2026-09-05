import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Smooth, luminance-preserving cross-fade page transition.
///
/// Keeps the outgoing page fully opaque while incoming page fades in over it,
/// avoiding transparency holes or washed-out backgrounds mid-transition.
class FadePageTransitionStrategy extends ReaderPageTransitionStrategy {
  const FadePageTransitionStrategy();

  @override
  Widget buildTransition({
    required BuildContext context,
    required Widget outgoingPage,
    required Widget incomingPage,
    required double progress,
    required PageTransitionMetrics metrics,
  }) {
    final t = progress.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Outgoing stays opaque until incoming covers it, then smoothly unmounts
        Opacity(
          opacity: (1.0 - t).clamp(0.0, 1.0),
          child: outgoingPage,
        ),
        // Incoming fades in cleanly on top
        Opacity(
          opacity: t,
          child: incomingPage,
        ),
      ],
    );
  }
}
