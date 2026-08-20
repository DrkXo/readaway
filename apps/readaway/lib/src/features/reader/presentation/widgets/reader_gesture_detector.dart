import 'package:flutter/material.dart';
import 'reader_overlay_controller.dart';

class ReaderGestureDetector extends StatelessWidget {
  const ReaderGestureDetector({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final ReaderOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => controller.toggleBars(),
      child: child,
    );
  }
}
