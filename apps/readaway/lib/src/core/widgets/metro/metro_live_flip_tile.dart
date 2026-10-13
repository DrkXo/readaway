import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'metro_pressable.dart';

/// A Lumia Inspired Live Tile that flips in 3D perspective
/// to reveal dynamic back-face information (reading stats, quote, summary).
class MetroLiveFlipTile extends StatefulWidget {
  const MetroLiveFlipTile({
    super.key,
    required this.front,
    required this.back,
    this.flipDuration = const Duration(milliseconds: 700),
    this.flipInterval,
    this.autoFlip = false,
    this.onTap,
    this.onLongPress,
    this.enableTilt = true,
  });

  /// Widget displayed on the front of the live tile.
  final Widget front;

  /// Widget displayed on the back of the live tile.
  final Widget back;

  /// Duration of the 180° 3D flip animation.
  final Duration flipDuration;

  /// Optional periodic interval between automated flips.
  final Duration? flipInterval;

  /// Whether the tile flips automatically on a timer.
  final bool autoFlip;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Callback when long pressed.
  final VoidCallback? onLongPress;

  /// Whether to also enable 3D press tilt via [MetroPressable].
  final bool enableTilt;

  @override
  State<MetroLiveFlipTile> createState() => MetroLiveFlipTileState();
}

class MetroLiveFlipTileState extends State<MetroLiveFlipTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _flipTimer;
  bool _isFront = true;

  /// Whether the tile currently shows the front face.
  bool get isFront => _isFront;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flipDuration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    if (widget.autoFlip && widget.flipInterval != null) {
      _startPeriodicFlip();
    }
  }

  void _startPeriodicFlip() {
    _flipTimer?.cancel();
    final interval = widget.flipInterval;
    if (!widget.autoFlip || interval == null) return;
    _flipTimer = Timer.periodic(interval, (_) => flip());
  }

  @override
  void didUpdateWidget(covariant MetroLiveFlipTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipDuration != widget.flipDuration) {
      _controller.duration = widget.flipDuration;
    }
    if (oldWidget.autoFlip != widget.autoFlip ||
        oldWidget.flipInterval != widget.flipInterval) {
      _startPeriodicFlip();
    }
  }

  /// Flip the live tile to its opposite face.
  void flip() {
    if (!mounted) return;
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (disableMotion) {
      setState(() => _isFront = !_isFront);
      return;
    }
    if (_controller.isAnimating) return;

    if (_isFront) {
      _controller.forward().then((_) {
        if (mounted) setState(() => _isFront = false);
      });
    } else {
      _controller.reverse().then((_) {
        if (mounted) setState(() => _isFront = true);
      });
    }
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);

    Widget buildFace() {
      if (disableMotion) {
        return _isFront ? widget.front : widget.back;
      }

      return AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          // Angle from 0 to pi (180 degrees)
          final angle = _animation.value * math.pi;
          final isUnderHalfway = angle < (math.pi / 2);

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // Perspective depth
            ..rotateY(angle);

          final currentChild = isUnderHalfway
              ? widget.front
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.back,
                );

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: currentChild,
          );
        },
      );
    }

    final content = buildFace();

    if (!widget.enableTilt) {
      return GestureDetector(
        onTap: widget.onTap ?? flip,
        onLongPress: widget.onLongPress,
        child: content,
      );
    }

    return MetroPressable(
      onTap: widget.onTap ?? flip,
      onLongPress: widget.onLongPress,
      child: content,
    );
  }
}
