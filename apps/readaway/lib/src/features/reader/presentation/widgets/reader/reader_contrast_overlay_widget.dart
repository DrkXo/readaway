import 'package:flutter/material.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';


class ReaderContrastOverlayWidget extends StatelessWidget {
  const ReaderContrastOverlayWidget({super.key, required this.intensity});
  final double intensity;

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0) return const SizedBox.shrink();
    return const SizedBox.expand().withContrastOverlay(1.0 + intensity);
  }
}
