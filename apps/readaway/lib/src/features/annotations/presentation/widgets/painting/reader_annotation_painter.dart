import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../domain/entity/reader_note.dart' show HighlightStyle;

/// One annotation resolved to the geometry it should be painted at.
class AnnotationPaint {
  const AnnotationPaint({
    required this.id,
    required this.rects,
    required this.style,
    required this.baseColor,
  });

  /// The note this paint belongs to, so a tap can be resolved back to a note.
  final String id;

  /// Chapter-local boxes covering the annotated text.
  final List<Rect> rects;

  /// How to draw it.
  final HighlightStyle style;

  /// The opaque colour the note resolved to.
  ///
  /// Opacity is applied at paint time rather than stored here, so the same note
  /// reads correctly on a light page and a dark one.
  final Color baseColor;
}

/// Paints the reader's highlights behind the text.
///
/// A sibling of the TTS speech-highlight painter, deliberately: both take
/// chapter-local rectangles plus the page's slice offset and support the same
/// three styles, so the two layers agree on where a passage is even though one
/// is authored by the reader and the other is transient.
class ReaderAnnotationPainter extends CustomPainter {
  const ReaderAnnotationPainter({
    required this.paints,
    required this.sliceTop,
    required this.brightness,
    required this.highContrast,
  });

  /// The annotations to draw, in the order they should be layered.
  final List<AnnotationPaint> paints;

  /// Chapter-local Y coordinate of the top of this page.
  final double sliceTop;

  /// The page's background brightness, which decides how much opacity the
  /// paint needs to be visible without hurting legibility.
  final Brightness brightness;

  /// Whether the reader has asked for increased contrast, which additionally
  /// outlines a filled highlight so it does not rely on colour alone.
  final bool highContrast;

  bool get _isDark => brightness == Brightness.dark;

  /// Fill opacity for a highlight, by background.
  ///
  /// A tint that reads as a mark on a light page all but disappears on a dark
  /// one, so the dark value is higher rather than the same. High contrast
  /// raises it further and adds an outline.
  double get _fillOpacity {
    if (highContrast) return _isDark ? 0.60 : 0.50;
    return _isDark ? 0.42 : 0.30;
  }

  /// Opacity for the underline and squiggly strokes.
  ///
  /// A line carries far fewer pixels than a fill, so at the fill's opacity it
  /// would be invisible.
  double get _strokeOpacity {
    if (highContrast) return 1.0;
    return _isDark ? 0.95 : 0.85;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (paints.isEmpty || size.isEmpty) return;
    final bounds = Offset.zero & size;

    for (final annotation in paints) {
      switch (annotation.style) {
        case HighlightStyle.highlight:
          _paintFill(canvas, bounds, annotation);
          // A filled highlight is the one style that can rely on colour alone,
          // so it is the one that needs the outline when contrast is boosted.
          if (highContrast) _paintOutline(canvas, bounds, annotation);
        case HighlightStyle.underline:
          _paintStroke(canvas, bounds, annotation, squiggly: false);
        case HighlightStyle.squiggly:
          _paintStroke(canvas, bounds, annotation, squiggly: true);
      }
    }
  }

  /// The visible part of each box, in page coordinates.
  ///
  /// Boxes are chapter-local, so they are translated by the slice offset and
  /// then clipped: a highlight that straddles a page break is drawn on both
  /// pages, each showing its own half.
  Iterable<Rect> _visibleRects(Rect bounds, AnnotationPaint annotation) sync* {
    for (final rect in annotation.rects) {
      final local = rect.translate(0, -sliceTop);
      if (!local.overlaps(bounds)) continue;
      final visible = local.intersect(bounds);
      if (visible.isEmpty || visible.width <= 0 || visible.height <= 0) {
        continue;
      }
      yield visible;
    }
  }

  void _paintFill(Canvas canvas, Rect bounds, AnnotationPaint annotation) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = annotation.baseColor.withValues(alpha: _fillOpacity);

    for (final rect in _visibleRects(bounds, annotation)) {
      canvas.drawRRect(_rounded(rect), paint);
    }
  }

  void _paintOutline(Canvas canvas, Rect bounds, AnnotationPaint annotation) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = annotation.baseColor.withValues(alpha: 1.0);

    for (final rect in _visibleRects(bounds, annotation)) {
      canvas.drawRRect(_rounded(rect.deflate(0.5)), paint);
    }
  }

  void _paintStroke(
    Canvas canvas,
    Rect bounds,
    AnnotationPaint annotation, {
    required bool squiggly,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = squiggly ? 1.5 : 2.0
      ..color = annotation.baseColor.withValues(alpha: _strokeOpacity);

    for (final rect in _visibleRects(bounds, annotation)) {
      final y = rect.bottom - 1.0;
      if (!squiggly) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
        continue;
      }

      final path = Path()..moveTo(rect.left, y);
      var x = rect.left;
      var up = true;
      const step = 3.5;
      while (x < rect.right) {
        x += step;
        path.lineTo(math.min(x, rect.right), up ? y - 2.0 : y + 1.0);
        up = !up;
      }
      canvas.drawPath(path, paint);
    }
  }

  RRect _rounded(Rect rect) =>
      RRect.fromRectAndRadius(rect, const Radius.circular(3.0));

  /// The id of the annotation under [pageLocal], or null when the tap missed.
  ///
  /// [pageLocal] is in the painter's own coordinates — the page's — so the
  /// chapter-local boxes are translated by the slice offset first. The test is
  /// inflated by [slop]: an underline is a 2px line and a squiggly is 1.5px, and
  /// requiring a reader to hit those exactly would make them unusable as tap
  /// targets.
  ///
  /// Annotations are searched last-painted first, so the annotation drawn on
  /// top is the one a tap selects.
  ///
  /// Not named `hitTest`: [CustomPainter] already declares that method for the
  /// widget tree's own hit testing, with a different meaning. This answers a
  /// reader-facing question, so it carries its own name.
  String? noteAt(Offset pageLocal, {double slop = 4.0}) {
    for (final annotation in paints.reversed) {
      for (final rect in annotation.rects) {
        if (rect.translate(0, -sliceTop).inflate(slop).contains(pageLocal)) {
          return annotation.id;
        }
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(ReaderAnnotationPainter oldDelegate) {
    if (oldDelegate.sliceTop != sliceTop ||
        oldDelegate.brightness != brightness ||
        oldDelegate.highContrast != highContrast) {
      return true;
    }
    if (oldDelegate.paints.length != paints.length) return true;

    for (var i = 0; i < paints.length; i++) {
      final previous = oldDelegate.paints[i];
      final current = paints[i];
      if (previous.id != current.id ||
          previous.style != current.style ||
          previous.baseColor != current.baseColor) {
        return true;
      }
      if (previous.rects.length != current.rects.length) return true;
      for (var j = 0; j < current.rects.length; j++) {
        if (previous.rects[j] != current.rects[j]) return true;
      }
    }
    return false;
  }
}
