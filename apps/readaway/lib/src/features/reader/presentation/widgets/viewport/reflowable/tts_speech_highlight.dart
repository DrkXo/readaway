import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Available visual styles for TTS highlights.
enum TtsHighlightStyle {
  /// Filled rounded rectangle.
  highlight,

  /// Clean baseline underline.
  underline,

  /// Wavy / squiggly underline.
  squiggly,

  /// Border outline.
  outline,
}

/// Paints a highlight behind or on top of the text currently being read aloud.
///
/// Supports dual-layer rendering:
/// - [rects]: Sentence-level bounding boxes in chapter-local coordinates.
/// - [wordRects]: Active word-level bounding boxes in chapter-local coordinates.
///
/// When [wordRects] is supplied, the active spoken word is highlighted with
/// higher visual prominence (karaoke-style focus) over the sentence background.
///
/// Passing [repaint] (such as a [ChangeNotifier] driven by audio playback ticks)
/// allows high-frequency word-highlight updates to repaint the canvas layer
/// without triggering expensive widget tree rebuilds.
class TtsSpeechHighlightPainter extends CustomPainter {
  const TtsSpeechHighlightPainter({
    required this.rects,
    required this.sliceTop,
    required this.color,
    this.wordRects,
    this.wordColor,
    this.style = TtsHighlightStyle.highlight,
    this.cornerRadius = 3.0,
    super.repaint,
  });

  /// Chapter-local bounding boxes covering the spoken text.
  final List<Rect> rects;

  /// Chapter-local bounding boxes covering the active spoken word, if any.
  final List<Rect>? wordRects;

  /// Chapter-local Y coordinate of the top of the visible page.
  final double sliceTop;

  /// Sentence fill or line colour. Expected to be translucent so the text stays readable.
  final Color color;

  /// Colour for the active spoken word highlight. Defaults to a higher opacity tint of [color].
  final Color? wordColor;

  /// Highlighting style (fill, underline, squiggly, outline).
  final TtsHighlightStyle style;

  /// Radius applied to each highlighted box.
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if ((rects.isEmpty && (wordRects == null || wordRects!.isEmpty)) ||
        size.isEmpty) {
      return;
    }

    final bounds = Offset.zero & size;

    // 1. Paint sentence-level highlight
    if (rects.isNotEmpty) {
      _paintBoxes(
        canvas: canvas,
        bounds: bounds,
        boxList: rects,
        style: style,
        drawColor: color,
        radius: cornerRadius,
      );
    }

    // 2. Paint active word-level highlight on top (karaoke focus pill)
    if (wordRects != null && wordRects!.isNotEmpty) {
      final activeWordColor =
          wordColor ??
          color.withValues(
            alpha: math.min(1.0, math.max(0.38, color.a * 2.0)),
          );
      _paintBoxes(
        canvas: canvas,
        bounds: bounds,
        boxList: wordRects!,
        style: TtsHighlightStyle.highlight,
        drawColor: activeWordColor,
        radius: math.max(2.0, cornerRadius),
      );
    }
  }

  void _paintBoxes({
    required Canvas canvas,
    required Rect bounds,
    required List<Rect> boxList,
    required TtsHighlightStyle style,
    required Color drawColor,
    required double radius,
  }) {
    final paint = Paint()..color = drawColor;

    for (final rect in boxList) {
      final local = rect.translate(0, -sliceTop);
      if (!local.overlaps(bounds)) {
        continue;
      }

      // Clamp to visible page bounds
      final visible = local.intersect(bounds);
      if (visible.isEmpty || visible.height <= 0 || visible.width <= 0) {
        continue;
      }

      switch (style) {
        case TtsHighlightStyle.highlight:
          paint.style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(visible, Radius.circular(radius)),
            paint,
          );
        case TtsHighlightStyle.underline:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawLine(
            Offset(visible.left, visible.bottom - 1.0),
            Offset(visible.right, visible.bottom - 1.0),
            paint,
          );
        case TtsHighlightStyle.squiggly:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          final path = Path();
          final y = visible.bottom - 1.0;
          path.moveTo(visible.left, y);
          var x = visible.left;
          var up = true;
          const step = 3.5;
          while (x < visible.right) {
            x += step;
            path.lineTo(math.min(x, visible.right), up ? y - 2.0 : y + 1.0);
            up = !up;
          }
          canvas.drawPath(path, paint);
        case TtsHighlightStyle.outline:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRRect(
            RRect.fromRectAndRadius(visible, Radius.circular(radius)),
            paint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(TtsSpeechHighlightPainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.wordColor != wordColor ||
        oldDelegate.style != style ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.sliceTop != sliceTop) {
      return true;
    }
    if (oldDelegate.rects.length != rects.length) return true;
    for (var i = 0; i < rects.length; i++) {
      if (oldDelegate.rects[i] != rects[i]) return true;
    }
    if ((oldDelegate.wordRects?.length ?? 0) != (wordRects?.length ?? 0)) {
      return true;
    }
    if (wordRects != null && oldDelegate.wordRects != null) {
      for (var i = 0; i < wordRects!.length; i++) {
        if (oldDelegate.wordRects![i] != wordRects![i]) return true;
      }
    }
    return false;
  }
}
