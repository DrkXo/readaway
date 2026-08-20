import 'package:flutter/material.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_overlay_controller.dart';

class ReaderGestureDetector extends StatelessWidget {
  const ReaderGestureDetector({
    super.key,
    required this.child,
    required this.controller,
    this.onTwoFingerTap,
  });

  final Widget child;
  final ReaderOverlayController controller;
  final VoidCallback? onTwoFingerTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildTapZone(
          context,
          heightFactor: 0.2,
          onTap: () => controller.showTopOnly(),
        ),
        _buildTapZone(
          context,
          top: 0.2,
          heightFactor: 0.6,
          onTap: () => controller.toggleBars(),
        ),
        _buildTapZone(
          context,
          top: 0.8,
          heightFactor: 0.2,
          onTap: () => controller.showBottomOnly(),
        ),
        child,
      ],
    );
  }

  Widget _buildTapZone(
    BuildContext context, {
    double top = 0,
    double heightFactor = 1,
    VoidCallback? onTap,
  }) {
    final height = MediaQuery.of(context).size.height;
    return Positioned(
      top: top * height,
      height: heightFactor * height,
      left: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}
