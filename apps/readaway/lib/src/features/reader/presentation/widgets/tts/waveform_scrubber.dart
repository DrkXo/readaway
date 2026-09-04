import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Interactive audio waveform progress bar with seek scrubbing.
///
/// Renders the synthesized audio peaks for the active sentence and allows
/// tapping or dragging horizontally to seek within the sentence.
class WaveformScrubber extends StatefulWidget {
  const WaveformScrubber({
    required this.position,
    required this.duration,
    this.waveform = const [],
    this.onSeek,
    this.height = 44,
    this.barSpacing = 2.5,
    this.barRadius = 2.0,
    this.playedColor,
    this.unplayedColor,
    this.handleColor,
    super.key,
  });

  /// Current playback progress position within the active sentence.
  final Duration position;

  /// Total duration of the active sentence audio.
  final Duration duration;

  /// Normalized peak amplitudes [0.0 .. 1.0] extracted during synthesis.
  final List<double> waveform;

  /// Callback when user scrubs or taps to seek.
  final ValueChanged<Duration>? onSeek;

  /// Height of the waveform bars area.
  final double height;

  /// Spacing between adjacent waveform bars.
  final double barSpacing;

  /// Corner radius of each bar.
  final double barRadius;

  /// Color of bars representing already-played audio.
  final Color? playedColor;

  /// Color of bars representing unplayed audio.
  final Color? unplayedColor;

  /// Color of the scrubber playhead indicator.
  final Color? handleColor;

  @override
  State<WaveformScrubber> createState() => _WaveformScrubberState();
}

class _WaveformScrubberState extends State<WaveformScrubber> {
  bool _isDragging = false;
  double? _dragFraction;

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleSeek(double localX, double totalWidth) {
    if (totalWidth <= 0 || widget.duration <= Duration.zero) return;
    final fraction = (localX / totalWidth).clamp(0.0, 1.0);
    setState(() {
      _dragFraction = fraction;
    });

    final targetMs = (fraction * widget.duration.inMilliseconds).round();
    widget.onSeek?.call(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playedColor = widget.playedColor ?? scheme.primary;
    final unplayedColor =
        widget.unplayedColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.22);
    final handleColor = widget.handleColor ?? scheme.primary;

    final durationMs = widget.duration.inMilliseconds;
    final positionMs = widget.position.inMilliseconds;

    final progressFraction = _isDragging && _dragFraction != null
        ? _dragFraction!
        : (durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0);

    final displayPos = _isDragging && _dragFraction != null
        ? Duration(milliseconds: (_dragFraction! * durationMs).round())
        : widget.position;

    final increasedPos = displayPos + const Duration(seconds: 2);
    final clampedIncreased =
        increasedPos > widget.duration ? widget.duration : increasedPos;
    final decreasedPos = displayPos - const Duration(seconds: 2);
    final clampedDecreased =
        decreasedPos < Duration.zero ? Duration.zero : decreasedPos;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Interactive Waveform Bars Canvas with Semantics
        Semantics(
          label: 'Playback position',
          value:
              '${_formatDuration(displayPos)} of ${_formatDuration(widget.duration)}',
          increasedValue:
              '${_formatDuration(clampedIncreased)} of ${_formatDuration(widget.duration)}',
          decreasedValue:
              '${_formatDuration(clampedDecreased)} of ${_formatDuration(widget.duration)}',
          slider: true,
          onIncrease: () {
            widget.onSeek?.call(clampedIncreased);
          },
          onDecrease: () {
            widget.onSeek?.call(clampedDecreased);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : 300.0;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  _handleSeek(details.localPosition.dx, width);
                },
                onHorizontalDragStart: (details) {
                  setState(() => _isDragging = true);
                  _handleSeek(details.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (details) {
                  _handleSeek(details.localPosition.dx, width);
                },
                onHorizontalDragEnd: (details) {
                  setState(() {
                    _isDragging = false;
                    _dragFraction = null;
                  });
                },
                onHorizontalDragCancel: () {
                  setState(() {
                    _isDragging = false;
                    _dragFraction = null;
                  });
                },
                child: SizedBox(
                  height: widget.height,
                  width: width,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      waveform: widget.waveform,
                      progressFraction: progressFraction,
                      playedColor: playedColor,
                      unplayedColor: unplayedColor,
                      handleColor: handleColor,
                      barSpacing: widget.barSpacing,
                      barRadius: widget.barRadius,
                      isDragging: _isDragging,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // 2. Position and Duration Timestamps
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(displayPos),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isDragging
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              Text(
                _formatDuration(widget.duration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.waveform,
    required this.progressFraction,
    required this.playedColor,
    required this.unplayedColor,
    required this.handleColor,
    required this.barSpacing,
    required this.barRadius,
    required this.isDragging,
  });

  final List<double> waveform;
  final double progressFraction;
  final Color playedColor;
  final Color unplayedColor;
  final Color handleColor;
  final double barSpacing;
  final double barRadius;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Use synthesized waveform or generate an aesthetically balanced placeholder
    final effectiveBars = waveform.isNotEmpty
        ? waveform
        : _generatePlaceholderBars(48);

    final count = effectiveBars.length;
    final totalSpacing = barSpacing * (count - 1);
    final barWidth = math.max(1.5, (size.width - totalSpacing) / count);

    final playedPaint = Paint()
      ..color = playedColor
      ..style = PaintingStyle.fill;

    final unplayedPaint = Paint()
      ..color = unplayedColor
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final playheadX = size.width * progressFraction;

    for (var i = 0; i < count; i++) {
      final x = i * (barWidth + barSpacing);
      final rawPeak = effectiveBars[i].clamp(0.08, 1.0);
      final barHeight = math.max(4.0, rawPeak * size.height);
      final top = centerY - barHeight / 2;

      final isPlayed = (x + barWidth / 2) <= playheadX;
      final paint = isPlayed ? playedPaint : unplayedPaint;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barRadius),
      );
      canvas.drawRRect(rrect, paint);
    }

    // Draw playhead scrubber indicator line
    final playheadPaint = Paint()
      ..color = handleColor
      ..strokeWidth = isDragging ? 2.5 : 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(playheadX, 2),
      Offset(playheadX, size.height - 2),
      playheadPaint,
    );

    // Draw scrubber thumb pip when dragging or hovered
    if (isDragging) {
      final pipPaint = Paint()
        ..color = handleColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(playheadX, centerY), 6.0, pipPaint);

      final pipBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(playheadX, centerY), 6.0, pipBorder);
    }
  }

  static List<double> _generatePlaceholderBars(int count) {
    return List.generate(count, (i) {
      final t = i / (count - 1);
      final bell = math.sin(t * math.pi);
      final ripple = 0.2 * math.sin(t * 12 * math.pi);
      return (bell * 0.7 + ripple + 0.15).clamp(0.1, 0.9);
    });
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progressFraction != progressFraction ||
        oldDelegate.waveform != waveform ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.unplayedColor != unplayedColor ||
        oldDelegate.handleColor != handleColor ||
        oldDelegate.isDragging != isDragging;
  }
}
