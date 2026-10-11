import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

/// Interactive container that implements the authentic Lumia Inspired
/// 3D perspective "tilt" effect on press.
///
/// When the user touches down, the surface physically tilts toward the contact
/// point using a 3D projection matrix ([Matrix4] with perspective entry) and scales down
/// slightly. On release, it snaps back with spring physics via [SingleMotionController].
class MetroPressable extends StatefulWidget {
  const MetroPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.maxTiltAngle = 0.10, // ~5.7 degrees
    this.pressedScale = 0.975,
    this.enabled = true,
    this.cursor = SystemMouseCursors.click,
    this.hitTestBehavior = HitTestBehavior.opaque,
  });

  /// The child widget to be tilted.
  final Widget child;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Callback when long pressed.
  final VoidCallback? onLongPress;

  /// Maximum tilt rotation in radians.
  final double maxTiltAngle;

  /// Scale multiplier while held down.
  final double pressedScale;

  /// Whether interactivity and tilt are active.
  final bool enabled;

  /// Cursor when hovered on desktop/web.
  final MouseCursor cursor;

  /// Hit test behavior for pointer events.
  final HitTestBehavior hitTestBehavior;

  @override
  State<MetroPressable> createState() => _MetroPressableState();
}

class _MetroPressableState extends State<MetroPressable>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _pressMotion;

  // Normalized touch coordinates in [-1.0, 1.0] relative to box center.
  double _tiltXNorm = 0.0;
  double _tiltYNorm = 0.0;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressMotion = SingleMotionController(
      motion: MaterialSpringMotion.expressiveSpatialDefault(),
      vsync: this,
      initialValue: 0.0,
    );
  }

  @override
  void dispose() {
    _pressMotion.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event, BoxConstraints constraints) {
    if (!widget.enabled ||
        (widget.onTap == null && widget.onLongPress == null)) {
      return;
    }

    final size = context.size;
    if (size == null || size.width == 0 || size.height == 0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Normalize touch from center: -1.0 (left/top) to +1.0 (right/bottom)
    final dx = (event.localPosition.dx - centerX) / centerX;
    final dy = (event.localPosition.dy - centerY) / centerY;

    setState(() {
      _tiltXNorm = dx.clamp(-1.0, 1.0);
      _tiltYNorm = dy.clamp(-1.0, 1.0);
      _isPressed = true;
    });

    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (disableMotion) {
      _pressMotion.value = 1.0;
    } else {
      _pressMotion.animateTo(1.0);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isPressed) return;
    final size = context.size;
    if (size == null || size.width == 0 || size.height == 0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final dx = (event.localPosition.dx - centerX) / centerX;
    final dy = (event.localPosition.dy - centerY) / centerY;

    setState(() {
      _tiltXNorm = dx.clamp(-1.0, 1.0);
      _tiltYNorm = dy.clamp(-1.0, 1.0);
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isPressed) return;
    _releasePress();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_isPressed) return;
    _releasePress();
  }

  void _releasePress() {
    setState(() => _isPressed = false);

    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (disableMotion) {
      _pressMotion.value = 0.0;
    } else {
      _pressMotion.animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          cursor: isInteractive ? widget.cursor : MouseCursor.defer,
          child: Listener(
            behavior: widget.hitTestBehavior,
            onPointerDown: (e) => _handlePointerDown(e, constraints),
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: GestureDetector(
              behavior: widget.hitTestBehavior,
              onTap: isInteractive ? widget.onTap : null,
              onLongPress: isInteractive ? widget.onLongPress : null,
              child: AnimatedBuilder(
                animation: _pressMotion,
                builder: (context, child) {
                  final t = _pressMotion.value;

                  if (t == 0.0) {
                    return child!;
                  }

                  // Rotation around X axis is driven by Y displacement (touch at bottom tilts up)
                  final rotX = -_tiltYNorm * widget.maxTiltAngle * t;
                  // Rotation around Y axis is driven by X displacement (touch at right tilts right)
                  final rotY = _tiltXNorm * widget.maxTiltAngle * t;
                  final scale = 1.0 - (1.0 - widget.pressedScale) * t;

                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.0015) // Authentic perspective distortion
                    ..rotateX(rotX)
                    ..rotateY(rotY)
                    ..scaleByDouble(scale, scale, 1.0, 1.0);

                  return Transform(
                    transform: transform,
                    alignment: FractionalOffset.center,
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
