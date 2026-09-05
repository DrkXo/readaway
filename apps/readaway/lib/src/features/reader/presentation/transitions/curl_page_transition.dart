import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'reader_page_transition_strategy.dart';

/// 3D perspective page turn / curl transition that simulates physical book page folding.
class CurlPageTransitionStrategy extends ReaderPageTransitionStrategy {
  const CurlPageTransitionStrategy();

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

    // We simulate 3D rotation around the spine.
    // When going forward (horizontal): spine is on the left, turning page rotates to the left (0 to -pi/2).
    // Incoming page underneath is revealed, or rotates from +pi/2 to 0.
    if (!isHorizontal) {
      // In vertical mode, rotate around horizontal axis (top/bottom)
      final turningPage = t < 0.5 ? outgoingPage : incomingPage;
      final currentAngle = t < 0.5 ? -t * math.pi : (1.0 - t) * math.pi;

      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(isForward ? currentAngle : -currentAngle);

      return Stack(
        fit: StackFit.expand,
        children: [
          if (t < 0.5) incomingPage else outgoingPage,
          Transform(
            transform: matrix,
            alignment: isForward ? Alignment.topCenter : Alignment.bottomCenter,
            child: turningPage,
          ),
        ],
      );
    }

    // Horizontal 3D Page Flip:
    // First half (t < 0.5): outgoing page turns from 0 to 90 degrees with perspective & shadow.
    // Second half (t >= 0.5): incoming page turns from 90 degrees to 0.
    final firstHalf = t < 0.5;
    final halfProgress = firstHalf ? t * 2.0 : (t - 0.5) * 2.0;

    // Rotation angle in radians
    final angle = firstHalf
        ? (isForward ? -halfProgress * (math.pi / 2) : halfProgress * (math.pi / 2))
        : (isForward
            ? (1.0 - halfProgress) * (math.pi / 2)
            : -(1.0 - halfProgress) * (math.pi / 2));

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(angle);

    final alignment = isForward
        ? (firstHalf ? Alignment.centerLeft : Alignment.centerRight)
        : (firstHalf ? Alignment.centerRight : Alignment.centerLeft);

    final activePage = firstHalf ? outgoingPage : incomingPage;
    final stationaryPage = firstHalf ? incomingPage : outgoingPage;

    // Shadow factor simulates ambient occlusion near the spine and fold angle
    final shadowAlpha = math.sin(t * math.pi) * 0.25;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Stationary page underneath
        stationaryPage,

        // Turning page with 3D perspective
        Transform(
          transform: matrix,
          alignment: alignment,
          child: Stack(
            fit: StackFit.expand,
            children: [
              activePage,
              if (shadowAlpha > 0.01)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: shadowAlpha),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Spine shadow gradient
        Positioned(
          left: isForward ? null : 0,
          right: isForward ? 0 : null,
          top: 0,
          bottom: 0,
          width: 32,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
                  end: isForward ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: shadowAlpha * 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
