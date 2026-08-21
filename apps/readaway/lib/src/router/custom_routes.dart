part of 'router.dart';

/// A modal bottom-sheet page designed for GoRouter with transparent sheet support.
class ModalPage<T> extends Page<T> {
  final WidgetBuilder builder;

  // Barrier Configuration
  final Color? modalBarrierColor;
  final bool barrierDismissible;
  final String? barrierLabel;
  final String? barrierOnTapHint;

  // Layout & Interaction
  final bool isScrollControlled;
  final bool useSafeArea;
  final bool enableDrag;
  final bool? showDragHandle;

  // Styling (Defaults to transparent sheet with zero elevation)
  final Color backgroundColor;
  final double elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;

  // Animation & Placement
  final AnimationController? transitionAnimationController;
  final AnimationStyle? sheetAnimationStyle;
  final Offset? anchorPoint;
  final CapturedThemes? capturedThemes;

  const ModalPage({
    required this.builder,
    this.modalBarrierColor,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierOnTapHint,
    this.isScrollControlled = true,
    this.useSafeArea = true,
    this.enableDrag = true,
    this.showDragHandle,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0.0,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.transitionAnimationController,
    this.sheetAnimationStyle,
    this.anchorPoint,
    this.capturedThemes,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      builder: builder,
      settings: this,
      capturedThemes: capturedThemes,
      barrierLabel: barrierLabel,
      barrierOnTapHint: barrierOnTapHint,
      modalBarrierColor: modalBarrierColor,
      isDismissible: barrierDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      transitionAnimationController: transitionAnimationController,
      sheetAnimationStyle: sheetAnimationStyle,
      anchorPoint: anchorPoint,
    );
  }
}
