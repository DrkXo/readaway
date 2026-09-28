import 'package:flutter/rendering.dart';

/// Paints a highlight behind the range of text currently being read aloud.
///
/// The rectangles come from the pagination coordinator in chapter-local
/// coordinates, the same space the chapter is laid out in. [sliceTop] is where
/// the visible page begins within that space, so subtracting it places the
/// highlight over the right screen position without the painter needing to
/// know anything about the viewport.
///
/// Rectangles belonging to other pages are skipped rather than clipped away.
/// The visible area already discards them, but skipping keeps a long chunk from
/// paying for a draw call per page it spans.
class TtsSpeechHighlightPainter extends CustomPainter {
  const TtsSpeechHighlightPainter({
    required this.rects,
    required this.sliceTop,
    required this.color,
    this.cornerRadius = 3.0,
  });

  /// Chapter-local bounding boxes covering the spoken text.
  final List<Rect> rects;

  /// Chapter-local Y coordinate of the top of the visible page.
  final double sliceTop;

  /// Fill colour. Expected to be translucent so the text stays readable.
  final Color color;

  /// Radius applied to each highlighted line box.
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (rects.isEmpty || size.isEmpty) return;

    final bounds = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final rect in rects) {
      final local = rect.translate(0, -sliceTop);
      if (!local.overlaps(bounds)) {
        continue;
      }

      // Clamp to the visible area so a range straddling a page break is drawn
      // only where it can be seen, rather than appearing to stop at the edge.
      final visible = local.intersect(bounds);
      if (visible.isEmpty || visible.height <= 0 || visible.width <= 0) {
        continue;
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(visible, Radius.circular(cornerRadius)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TtsSpeechHighlightPainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.sliceTop != sliceTop) {
      return true;
    }
    if (oldDelegate.rects.length != rects.length) return true;
    for (var i = 0; i < rects.length; i++) {
      if (oldDelegate.rects[i] != rects[i]) return true;
    }
    return false;
  }
}
