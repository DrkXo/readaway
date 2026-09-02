import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReaderBrightnessOverlayWidget extends StatelessWidget {
  const ReaderBrightnessOverlayWidget({super.key, required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Animate(
      effects: [FadeEffect(duration: 200.ms, curve: Curves.easeOut)],
      child: Container(color: Colors.black.withValues(alpha: opacity)),
    );
  }
}
