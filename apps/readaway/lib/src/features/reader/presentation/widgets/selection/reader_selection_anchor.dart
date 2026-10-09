import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_render/hyper_render.dart'
    show
        HyperSelectionAnchorBuilder,
        HyperSelectionAnchorDetails,
        HyperSelectionAnchorType;
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

/// Premium, touch-ergonomic text selection anchor widget for Readaway.
///
/// Features:
/// - Expanded 44x44pt hit target adhering to mobile touch guidelines.
/// - Spring-animated scale (1.2x) and elevated glow when [HyperSelectionAnchorDetails.isDragging] is true.
/// - Subtle tactile haptic feedback ([HapticFeedback.selectionClick]) on drag start/end.
/// - Contrast border and ambient drop shadow ensuring visibility across all reader themes.
/// - Multiple styles: [ReaderAnchorStyle.modernPin] (default), [ReaderAnchorStyle.lollipop],
///   [ReaderAnchorStyle.minimalPill], and [ReaderAnchorStyle.classicTeardrop].
class ReaderSelectionAnchor extends StatefulWidget {
  const ReaderSelectionAnchor({
    super.key,
    required this.details,
    this.style = ReaderAnchorStyle.modernPin,
    this.enableHaptics = true,
  });

  final HyperSelectionAnchorDetails details;
  final ReaderAnchorStyle style;
  final bool enableHaptics;

  /// Creates a [HyperSelectionAnchorBuilder] that returns a [ReaderSelectionAnchor].
  static HyperSelectionAnchorBuilder builder({
    ReaderAnchorStyle style = ReaderAnchorStyle.modernPin,
    bool enableHaptics = true,
  }) {
    return (context, details) => ReaderSelectionAnchor(
      details: details,
      style: style,
      enableHaptics: enableHaptics,
    );
  }

  @override
  State<ReaderSelectionAnchor> createState() => _ReaderSelectionAnchorState();
}

class _ReaderSelectionAnchorState extends State<ReaderSelectionAnchor> {
  @override
  void didUpdateWidget(covariant ReaderSelectionAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableHaptics) {
      if (!oldWidget.details.isDragging && widget.details.isDragging) {
        HapticFeedback.selectionClick();
      } else if (oldWidget.details.isDragging && !widget.details.isDragging) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final details = widget.details;

    // Use handle color or fallback to theme primary / selectionHandleColor
    final effectiveColor = details.handleColor != Colors.transparent
        ? details.handleColor
        : (theme.textSelectionTheme.selectionHandleColor ??
              context.appColors.scheme.primary);

    final semanticLabel = details.isStart
        ? 'Selection start handle'
        : 'Selection end handle';

    return Semantics(
      label: semanticLabel,
      button: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedScale(
          scale: details.isDragging ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          alignment: details.isStart
              ? Alignment.bottomCenter
              : Alignment.topCenter,
          child: CustomPaint(
            size: const Size(44, 44),
            painter: _ReaderSelectionAnchorPainter(
              type: details.type,
              style: widget.style,
              color: effectiveColor,
              isDark: isDark,
              isDragging: details.isDragging,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderSelectionAnchorPainter extends CustomPainter {
  _ReaderSelectionAnchorPainter({
    required this.type,
    required this.style,
    required this.color,
    required this.isDark,
    required this.isDragging,
  });

  final HyperSelectionAnchorType type;
  final ReaderAnchorStyle style;
  final Color color;
  final bool isDark;
  final bool isDragging;

  bool get isStart => type == HyperSelectionAnchorType.start;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; // 22.0

    // Reference attachment points:
    // For isStart: bottom-center (22.0, size.height) touches the text top-left.
    // For isEnd: top-center (22.0, 0.0) touches the text bottom-right.
    final targetY = isStart ? size.height : 0.0;

    switch (style) {
      case ReaderAnchorStyle.modernPin:
        _paintModernPin(canvas, size, cx, targetY);
        break;
      case ReaderAnchorStyle.lollipop:
        _paintLollipop(canvas, size, cx, targetY);
        break;
      case ReaderAnchorStyle.minimalPill:
        _paintMinimalPill(canvas, size, cx, targetY);
        break;
      case ReaderAnchorStyle.classicTeardrop:
        _paintClassicTeardrop(canvas, size, cx, targetY);
        break;
    }
  }

  void _paintModernPin(Canvas canvas, Size size, double cx, double targetY) {
    // Pin bulb center
    final bulbCenterY = isStart ? targetY - 20.0 : targetY + 20.0;
    const bulbRadius = 8.5;

    final path = Path();
    if (isStart) {
      // Tip points down at (cx, targetY)
      path.moveTo(cx, targetY);
      path.lineTo(cx - 3.0, targetY - 8.0);
      path.arcToPoint(
        Offset(cx + 3.0, targetY - 8.0),
        radius: const Radius.circular(bulbRadius),
        clockwise: true,
      );
      path.close();
    } else {
      // Tip points up at (cx, targetY)
      path.moveTo(cx, targetY);
      path.lineTo(cx + 3.0, targetY + 8.0);
      path.arcToPoint(
        Offset(cx - 3.0, targetY + 8.0),
        radius: const Radius.circular(bulbRadius),
        clockwise: true,
      );
      path.close();
    }

    _drawPathWithEffects(canvas, path, Offset(cx, bulbCenterY));
  }

  void _paintLollipop(Canvas canvas, Size size, double cx, double targetY) {
    final bulbCenterY = isStart ? targetY - 22.0 : targetY + 22.0;
    const bulbRadius = 7.5;

    // Stem line
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawLine(
      Offset(cx, targetY),
      Offset(cx, bulbCenterY),
      stemShadowPaint,
    );
    canvas.drawLine(
      Offset(cx, targetY),
      Offset(cx, bulbCenterY),
      stemPaint,
    );

    // Bulb circle
    final bulbPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(cx, bulbCenterY),
          radius: bulbRadius,
        ),
      );

    _drawPathWithEffects(canvas, bulbPath, Offset(cx, bulbCenterY));
  }

  void _paintMinimalPill(Canvas canvas, Size size, double cx, double targetY) {
    const pillW = 14.0;
    const pillH = 24.0;
    final pillTop = isStart ? targetY - 28.0 : targetY + 4.0;
    final pillRect = Rect.fromLTWH(cx - pillW / 2, pillTop, pillW, pillH);
    final rrect = RRect.fromRectAndRadius(
      pillRect,
      const Radius.circular(pillW / 2),
    );

    final path = Path()..addRRect(rrect);
    _drawPathWithEffects(canvas, path, pillRect.center);

    // Subtle micro grip lines inside pill
    final gripPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final centerY = pillRect.center.dy;
    canvas.drawLine(
      Offset(cx - 3.5, centerY - 2.5),
      Offset(cx + 3.5, centerY - 2.5),
      gripPaint,
    );
    canvas.drawLine(
      Offset(cx - 3.5, centerY + 2.5),
      Offset(cx + 3.5, centerY + 2.5),
      gripPaint,
    );
  }

  void _paintClassicTeardrop(
    Canvas canvas,
    Size size,
    double cx,
    double targetY,
  ) {
    const r = 10.0;
    final path = Path();
    if (isStart) {
      // Circle centered at (cx - r, targetY - r), pointing down-right to (cx, targetY)
      final center = Offset(cx - r / 2, targetY - r * 1.5);
      path.moveTo(cx, targetY);
      path.arcTo(
        Rect.fromCircle(center: center, radius: r),
        math.pi / 4,
        math.pi * 1.5,
        false,
      );
      path.close();
      _drawPathWithEffects(canvas, path, center);
    } else {
      // Circle centered at (cx + r, targetY + r), pointing up-left to (cx, targetY)
      final center = Offset(cx + r / 2, targetY + r * 1.5);
      path.moveTo(cx, targetY);
      path.arcTo(
        Rect.fromCircle(center: center, radius: r),
        -3 * math.pi / 4,
        math.pi * 1.5,
        false,
      );
      path.close();
      _drawPathWithEffects(canvas, path, center);
    }
  }

  void _drawPathWithEffects(Canvas canvas, Path path, Offset center) {
    // 1. Ambient drop shadow & dragging glow
    final shadowBlur = isDragging ? 12.0 : 6.0;
    final shadowAlpha = isDragging ? 0.32 : 0.18;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);

    canvas.save();
    canvas.translate(0, isDragging ? 2.5 : 1.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. Active glow halo when dragging
    if (isDragging) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(path, glowPaint);
    }

    // 3. Main solid fill with subtle top-to-bottom shading
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.12) ?? color,
          Color.lerp(color, Colors.black, 0.08) ?? color,
        ],
      ).createShader(path.getBounds());
    canvas.drawPath(path, fillPaint);

    // 4. Crisp high-contrast outer rim
    final rimColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.16);

    final rimPaint = Paint()
      ..color = rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, rimPaint);

    // 5. Specular highlight dot for physical tactile feel
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.45 : 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - 2.5, center.dy - 2.5),
      1.8,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReaderSelectionAnchorPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.style != style ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isDragging != isDragging;
  }
}
