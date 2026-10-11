import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Extension adding authentic Lumia Inspired stagger entrances
/// to widgets inside lists, grids, and hubs.
extension MetroTurnstileAnimationX on Widget {
  /// Animates the widget with a cascading entrance:
  /// a subtle horizontal slide from the right paired with rapid fade-in,
  /// delayed proportionally by [index].
  Widget metroStaggerEntrance({
    required BuildContext context,
    int index = 0,
    Duration delayPerItem = const Duration(milliseconds: 35),
    Duration duration = const Duration(milliseconds: 240),
  }) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (disableMotion) return this;

    final initialDelay = delayPerItem * index;

    return animate(delay: initialDelay)
        .fadeIn(
          duration: duration,
          curve: Curves.easeOutCubic,
        )
        .slideX(
          begin: 0.10,
          end: 0.0,
          duration: duration + const Duration(milliseconds: 40),
          curve: Curves.easeOutCubic,
        );
  }
}

/// Metro Pivot page transition inspired by Windows Phone / Lumia design.
///
/// In authentic Metro / Windows Phone design, moving between views and pages
/// is modeled as shifting across a panoramic horizon:
/// - **Horizontal Parallax Glide**:
///   - Primary page (`animation`) enters from the right with a subtle offset
///     (`Offset(0.20, 0.0)` -> `Offset.zero`) decelerating smoothly via
///     [Curves.easeOutCubic] for a signature "Fast and Fluid" feel.
///   - Secondary page (`secondaryAnimation`) recedes to the left with subtle
///     parallax (`Offset.zero` -> `Offset(-0.08, 0.0)`).
/// - **Silky Hardware-Composited Crossfade**:
///   - Incoming page rapidly crossfades in from 0% to 100% opacity within the first
///     65% of the transition so content is immediately legible while settling.
///   - Receding page dims and fades to 0% as the new page covers it.
/// - **Zero Jank & Zero 3D Distortion**:
///   - Built strictly with Flutter's composited [SlideTransition] and [FadeTransition].
///   - No Matrix4 3D perspective rotation, avoiding raster-cache invalidations,
///     subpixel text jitter, and offscreen framebuffer thrashing.
///   - Complete bypass when [MediaQuery.disableAnimationsOf] is active.
class MetroPivotTransition extends StatefulWidget {
  const MetroPivotTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<MetroPivotTransition> createState() => _MetroPivotTransitionState();
}

class _MetroPivotTransitionState extends State<MetroPivotTransition> {
  late CurvedAnimation _primarySlideCurve;
  late CurvedAnimation _primaryFadeCurve;
  late CurvedAnimation _secondarySlideCurve;
  late CurvedAnimation _secondaryFadeCurve;

  late Animation<Offset> _primarySlide;
  late Animation<double> _primaryFade;
  late Animation<Offset> _secondarySlide;
  late Animation<double> _secondaryFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _primarySlideCurve = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _primaryFadeCurve = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      reverseCurve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );
    _secondarySlideCurve = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _secondaryFadeCurve = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: const Interval(0.0, 0.85, curve: Curves.easeIn),
      reverseCurve: const Interval(0.15, 1.0, curve: Curves.easeOut),
    );

    _primarySlide = Tween<Offset>(
      begin: const Offset(0.20, 0.0),
      end: Offset.zero,
    ).animate(_primarySlideCurve);

    _primaryFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_primaryFadeCurve);

    _secondarySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.08, 0.0),
    ).animate(_secondarySlideCurve);

    _secondaryFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_secondaryFadeCurve);
  }

  void _disposeAnimations() {
    _primarySlideCurve.dispose();
    _primaryFadeCurve.dispose();
    _secondarySlideCurve.dispose();
    _secondaryFadeCurve.dispose();
  }

  @override
  void didUpdateWidget(MetroPivotTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation ||
        widget.secondaryAnimation != oldWidget.secondaryAnimation) {
      _disposeAnimations();
      _initAnimations();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (disableMotion) return widget.child;

    return SlideTransition(
      position: _secondarySlide,
      child: FadeTransition(
        opacity: _secondaryFade,
        child: SlideTransition(
          position: _primarySlide,
          child: FadeTransition(
            opacity: _primaryFade,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible alias for [MetroPivotTransition].
///
/// Replaced the legacy 3D rotation turnstile with the silky, hardware-composited
/// Metro Pivot horizontal parallax slide & crossfade.
class MetroTurnstileTransition extends MetroPivotTransition {
  const MetroTurnstileTransition({
    super.key,
    required super.animation,
    required super.secondaryAnimation,
    required super.child,
  });
}

/// A [CustomTransitionPage] implementing the Lumia Metro Pivot page transition
/// for GoRouter navigation.
class MetroPivotPage<T> extends CustomTransitionPage<T> {
  MetroPivotPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
    super.transitionDuration = const Duration(milliseconds: 260),
    super.reverseTransitionDuration = const Duration(milliseconds: 220),
  }) : super(
         transitionsBuilder:
             (
               context,
               animation,
               secondaryAnimation,
               child,
             ) => MetroPivotTransition(
               animation: animation,
               secondaryAnimation: secondaryAnimation,
               child: child,
             ),
       );
}

/// A [CustomTransitionPage] implementing the Lumia Metro turnstile transition
/// (aliased to [MetroPivotPage] for 60fps hardware-composited performance).
class MetroTurnstilePage<T> extends MetroPivotPage<T> {
  MetroTurnstilePage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
    super.transitionDuration = const Duration(milliseconds: 260),
    super.reverseTransitionDuration = const Duration(milliseconds: 220),
  });
}

/// A [PageTransitionsBuilder] implementing the signature Lumia / Windows Phone
/// Pivot navigation transition.
class MetroPivotTransitionsBuilder extends PageTransitionsBuilder {
  const MetroPivotTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return MetroPivotTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Alias for [MetroPivotTransitionsBuilder] maintaining backward compatibility.
class MetroTurnstileTransitionsBuilder extends MetroPivotTransitionsBuilder {
  const MetroTurnstileTransitionsBuilder();
}
