import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// Instant cut page transition without animation (ideal for e-ink or instant paging).
class NonePageTransitionStrategy extends ReaderPageTransitionStrategy {
  const NonePageTransitionStrategy();

  @override
  Widget buildTransition({
    required BuildContext context,
    required Widget outgoingPage,
    required Widget incomingPage,
    required double progress,
    required PageTransitionMetrics metrics,
  }) {
    return progress < 0.5 ? outgoingPage : incomingPage;
  }
}
