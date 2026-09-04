import 'package:flutter/material.dart';

/// Full-screen black overlay to dim reader brightness beyond system minimums.
class ReaderBrightnessOverlay extends StatelessWidget {
  const ReaderBrightnessOverlay({super.key, required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: opacity.clamp(0.0, 1.0)),
        child: const SizedBox.expand(),
      ),
    );
  }
}
