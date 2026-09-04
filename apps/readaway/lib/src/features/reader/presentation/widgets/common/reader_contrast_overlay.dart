import 'package:flutter/material.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// Full-screen high-contrast overlay for reader text legibility.
class ReaderContrastOverlay extends StatelessWidget {
  const ReaderContrastOverlay({super.key, required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: const SizedBox.expand().withContrastOverlay(1.0 + intensity),
    );
  }
}
