import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints a transient search-hit rectangle on top of a virtual page.
///
/// Painted as a thin outline so it stays visible on every page background
/// without hiding the underlying text or highlights.
class ReaderSearchHighlightPainter extends CustomPainter {
  const ReaderSearchHighlightPainter({
    required this.rects,
    required this.sliceTop,
    required this.color,
  });

  final List<Rect> rects;
  final double sliceTop;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (rects.isEmpty || size.isEmpty) return;
    final bounds = Offset.zero & size;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withValues(alpha: math.min(1.0, color.a + 0.25));

    for (final rect in rects) {
      final local = rect.translate(0, -sliceTop);
      if (!local.overlaps(bounds)) continue;
      final visible = local.intersect(bounds);
      if (visible.isEmpty) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(visible, const Radius.circular(4.0)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(visible, const Radius.circular(4.0)),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReaderSearchHighlightPainter oldDelegate) =>
      oldDelegate.sliceTop != sliceTop ||
      oldDelegate.color != color ||
      oldDelegate.rects.length != rects.length ||
      !_rectsEqual(oldDelegate.rects, rects);

  static bool _rectsEqual(List<Rect> a, List<Rect> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
