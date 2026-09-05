import 'package:flutter/material.dart';

import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

/// Context and layout metrics provided to a [ReaderPageTransitionStrategy].
@immutable
class PageTransitionMetrics {
  const PageTransitionMetrics({
    required this.viewportSize,
    required this.direction,
    required this.isForward,
  });

  /// The dimensions of the reader viewport.
  final Size viewportSize;

  /// Whether pages transition horizontally or vertically.
  final ReaderScrollDirection direction;

  /// True when advancing forward (next page), false when retreating (previous page).
  final bool isForward;

  /// Viewport width.
  double get width => viewportSize.width;

  /// Viewport height.
  double get height => viewportSize.height;

  /// True when transition moves horizontally.
  bool get isHorizontal => direction == ReaderScrollDirection.horizontal;
}

/// Abstract contract for reader page transitions.
///
/// Implementations construct a composite widget transitioning from [outgoingPage]
/// to [incomingPage] based on [progress] (0.0 to 1.0).
///
/// This architecture decouples the visual transition effect from the viewport,
/// gesture handling, and animation controller, allowing any custom transition
/// (including 3D curls, covers, shaders, or custom curves) to be added without
/// modifying core viewer code.
abstract class ReaderPageTransitionStrategy {
  const ReaderPageTransitionStrategy();

  /// Builds the composite transition widget.
  ///
  /// - [progress]: Normalized progress from `0.0` (outgoing fully active) to
  ///   `1.0` (incoming fully active).
  /// - [outgoingPage]: The page being transitioned away from.
  /// - [incomingPage]: The page being transitioned into.
  /// - [metrics]: Viewport geometry, direction, and forward/backward orientation.
  Widget buildTransition({
    required BuildContext context,
    required Widget outgoingPage,
    required Widget incomingPage,
    required double progress,
    required PageTransitionMetrics metrics,
  });
}
