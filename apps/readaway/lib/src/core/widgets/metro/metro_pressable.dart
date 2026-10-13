import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

/// Interactive container that implements the authentic Lumia Inspired
/// 3D perspective "tilt" effect on press.
class MetroPressable extends StatefulWidget {
  const MetroPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.maxTiltAngle = 0.10,
    this.pressedScale = 0.975,
    this.enabled = true,
    this.cursor = SystemMouseCursors.click,
    this.hitTestBehavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double maxTiltAngle;
  final double pressedScale;
  final bool enabled;
  final MouseCursor cursor;
  final HitTestBehavior hitTestBehavior;

  @override
  State<MetroPressable> createState() => _MetroPressableState();
}

class _MetroPressableState extends State<MetroPressable>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _pressMotion;
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);
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
    _tilt.dispose();
    _pressMotion.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled ||
        (widget.onTap == null && widget.onLongPress == null)) {
      return;
    }

    _updateTilt(event.localPosition);
    setState(() => _isPressed = true);

    if (MediaQuery.disableAnimationsOf(context)) {
      _pressMotion.value = 1.0;
    } else {
      _pressMotion.animateTo(1.0);
    }
  }

  void _updateTilt(Offset position) {
    final size = context.size;
    if (size == null || size.width == 0 || size.height == 0) return;

    final dx = (position.dx - size.width / 2) / (size.width / 2);
    final dy = (position.dy - size.height / 2) / (size.height / 2);
    _tilt.value = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isPressed) _updateTilt(event.localPosition);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isPressed) _releasePress();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isPressed) _releasePress();
  }

  void _releasePress() {
    setState(() => _isPressed = false);

    if (MediaQuery.disableAnimationsOf(context)) {
      _pressMotion.value = 0.0;
    } else {
      _pressMotion.animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);

    return MouseRegion(
      cursor: isInteractive ? widget.cursor : MouseCursor.defer,
      child: Listener(
        behavior: widget.hitTestBehavior,
        onPointerDown: _handlePointerDown,
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
              return ValueListenableBuilder<Offset>(
                valueListenable: _tilt,
                builder: (context, tilt, child) {
                  final t = _pressMotion.value;
                  if (t == 0.0) return child!;

                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateX(-tilt.dy * widget.maxTiltAngle * t)
                    ..rotateY(tilt.dx * widget.maxTiltAngle * t)
                    ..scaleByDouble(
                      1.0 - (1.0 - widget.pressedScale) * t,
                      1.0 - (1.0 - widget.pressedScale) * t,
                      1.0,
                      1.0,
                    );

                  return Transform(
                    transform: transform,
                    alignment: FractionalOffset.center,
                    child: child,
                  );
                },
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
