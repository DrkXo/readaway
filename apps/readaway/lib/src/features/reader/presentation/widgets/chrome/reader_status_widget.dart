import 'dart:async';
import 'package:flutter/material.dart';

/// Displays current time and battery status in the reader's running footer.
class ReaderStatusWidget extends StatefulWidget {
  const ReaderStatusWidget({
    super.key,
    required this.showTime,
    required this.showBattery,
    this.use24Hour = true,
    this.fontSize = 11.0,
    this.color,
  });

  final bool showTime;
  final bool showBattery;
  final bool use24Hour;
  final double fontSize;
  final Color? color;

  @override
  State<ReaderStatusWidget> createState() => _ReaderStatusWidgetState();
}

class _ReaderStatusWidgetState extends State<ReaderStatusWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.showTime) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(ReaderStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showTime && !oldWidget.showTime) {
      _startTimer();
    } else if (!widget.showTime && oldWidget.showTime) {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _now = DateTime.now();
    // Align to the next minute boundary
    final secondsUntilNextMinute = 60 - _now.second;
    _timer = Timer(Duration(seconds: secondsUntilNextMinute), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    if (widget.use24Hour) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showTime && !widget.showBattery) {
      return const SizedBox.shrink();
    }

    final textColor = widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final textStyle = TextStyle(
      fontSize: widget.fontSize,
      color: textColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showTime)
          Text(
            _formatTime(_now),
            style: textStyle,
          ),
        if (widget.showTime && widget.showBattery)
          const SizedBox(width: 8),
        if (widget.showBattery)
          _BatteryIcon(
            fontSize: widget.fontSize,
            color: textColor,
          ),
      ],
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon({
    required this.fontSize,
    required this.color,
  });

  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = fontSize * 1.8;
    final height = fontSize * 0.9;

    return SizedBox(
      width: width + 2.0,
      height: height,
      child: CustomPaint(
        painter: _BatteryPainter(color: color),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyWidth = size.width - 2.5;
    final bodyHeight = size.height;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, bodyWidth - 1.0, bodyHeight - 1.0),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(rrect, borderPaint);

    // Tip
    final tipPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final tipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyWidth, (bodyHeight - 4.0) / 2, 2.0, 4.0),
      const Radius.circular(0.5),
    );
    canvas.drawRRect(tipRect, tipPaint);

    // Inner level (default ~75% visual indicator)
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final fillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.0, 2.0, (bodyWidth - 4.0) * 0.75, bodyHeight - 4.0),
      const Radius.circular(1.0),
    );
    canvas.drawRRect(fillRRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.color != color;
}
