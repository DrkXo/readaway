part of '../core_widgets.dart';

extension OverlayWidgetExtensions on Widget {
  Widget withContrastOverlay(double contrast) => Animate(
    effects: [
      FadeEffect(duration: 200.ms, curve: Curves.easeOut),
    ],
    child: ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        contrast,
        0,
        0,
        0,
        0,
        0,
        contrast,
        0,
        0,
        0,
        0,
        0,
        contrast,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: this,
    ),
  );
}
