import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated live speech waveform indicator.
///
/// Features oscillating harmonic bars that dance smoothly when [isPlaying] is true
/// and settle into a quiet resting state when paused or idle.
class LiveSpeechWaveform extends StatefulWidget {
  const LiveSpeechWaveform({
    required this.isPlaying,
    this.color,
    this.barCount = 4,
    this.height = 20,
    this.width = 24,
    this.spacing = 2.0,
    this.barRadius = 2.0,
    super.key,
  });

  /// Whether playback is currently active.
  final bool isPlaying;

  /// Waveform bar color. Defaults to Theme primary color.
  final Color? color;

  /// Number of vertical waveform bars.
  final int barCount;

  /// Total widget height.
  final double height;

  /// Total widget width.
  final double width;

  /// Spacing between bars.
  final double spacing;

  /// Border radius of each bar.
  final double barRadius;

  @override
  State<LiveSpeechWaveform> createState() => _LiveSpeechWaveformState();
}

class _LiveSpeechWaveformState extends State<LiveSpeechWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LiveSpeechWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.animateTo(0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final barCount = math.max(1, widget.barCount);
    final totalSpacing = widget.spacing * (barCount - 1);
    final barWidth = math.max(1.5, (widget.width - totalSpacing) / barCount);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (index) {
              // Staggered sine oscillation per bar for organic speech cadence
              final phaseOffset = index * (math.pi / (barCount * 0.75));
              final speedMultiplier = 1.0 + (index % 2) * 0.4;
              final rawWave = math.sin(t * speedMultiplier + phaseOffset);

              // Scale wave between minFraction (resting) and 1.0 (active)
              const minFraction = 0.25;
              final waveFraction = widget.isPlaying
                  ? minFraction + (1.0 - minFraction) * ((rawWave + 1.0) / 2.0)
                  : minFraction;

              final barHeight = (widget.height * waveFraction).clamp(
                widget.barRadius * 2,
                widget.height,
              );

              return Container(
                margin: EdgeInsets.only(
                  right: index < barCount - 1 ? widget.spacing : 0,
                ),
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(widget.barRadius),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
