import 'package:flutter/material.dart';

/// Flat rectangular slider thumb shape matching Metro / Modern Lumia design language.
///
/// Replaces standard circular slider thumbs with a crisp, borderless rectangular
/// indicator.
class MetroSliderThumbShape extends SliderComponentShape {
  const MetroSliderThumbShape({
    this.thumbRadius = 7.0,
    this.aspectRatio = 1.0,
  });

  /// Half-width / radius of the rectangular thumb.
  final double thumbRadius;

  /// Aspect ratio of width to height (1.0 = square, < 1.0 = vertical pill/tick).
  final double aspectRatio;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(thumbRadius * 2, thumbRadius * 2 / aspectRatio);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final color = sliderTheme.thumbColor ?? Colors.white;
    final width = thumbRadius * 2;
    final height = thumbRadius * 2 / aspectRatio;
    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    canvas.drawRect(rect, Paint()..color = color);
  }
}
