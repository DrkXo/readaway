library;

import 'package:flutter/material.dart';
import 'package:readaway_core/readaway_core.dart';

import '../widgets/metro/metro_page_transition.dart';

export 'package:readaway_core/readaway_core.dart'
    show VsCodeTheme, VsCodeThemeColorX, BuiltinVsCodeThemes;

/// Convenient alias mapping legacy [AppColors] to [VsCodeTheme].
typedef AppColors = VsCodeTheme;

/// Default page transition animations for the application.
///
/// Uses the Lumia / Windows Phone [MetroPivotTransitionsBuilder] for smooth,
/// hardware-composited horizontal parallax glide and crossfade transitions
/// across all target platforms.
const PageTransitionsTheme appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: MetroPivotTransitionsBuilder(),
    TargetPlatform.iOS: MetroPivotTransitionsBuilder(),
    TargetPlatform.linux: MetroPivotTransitionsBuilder(),
    TargetPlatform.macOS: MetroPivotTransitionsBuilder(),
    TargetPlatform.windows: MetroPivotTransitionsBuilder(),
  },
);

/// Theme extension to attach the active [VsCodeTheme] to Flutter's [ThemeData].
@immutable
class VsCodeThemeExtension extends ThemeExtension<VsCodeThemeExtension> {
  const VsCodeThemeExtension(this.theme);

  final VsCodeTheme theme;

  @override
  VsCodeThemeExtension copyWith({VsCodeTheme? theme}) =>
      VsCodeThemeExtension(theme ?? this.theme);

  @override
  VsCodeThemeExtension lerp(
    ThemeExtension<VsCodeThemeExtension>? other,
    double t,
  ) {
    if (other is! VsCodeThemeExtension) return this;
    if (t < 0.5) return this;
    return other;
  }
}

/// Shared motion tokens for transitions and micro-interactions.
///
/// Durations are sized by the distance and complexity of the change they cover
/// rather than copied from transition to transition, and the whole set
/// collapses to [Duration.zero] when the platform "reduce motion"
/// accessibility setting is enabled.
@immutable
class AppMotion {
  const AppMotion({
    required this.fast,
    required this.standard,
    required this.enter,
    this.page = const Duration(milliseconds: 260),
    this.pageReverse = const Duration(milliseconds: 220),
    this.exit = Curves.easeInCubic,
  });

  /// Immediate feedback for small state changes, such as a chip press.
  final Duration fast;

  /// Layout-level change, such as expanding or collapsing a panel.
  final Duration standard;

  /// Full-page horizon shift / navigation transition.
  final Duration page;

  /// Reverse transition duration when popping a page.
  final Duration pageReverse;

  /// Decelerating curve for content arriving on screen.
  final Curve enter;

  /// Accelerating or subtle curve for content leaving screen.
  final Curve exit;

  /// The default token set, or an all-zero set when motion is disabled.
  factory AppMotion.resolve({required bool disableAnimations}) {
    if (disableAnimations) {
      return const AppMotion(
        fast: Duration.zero,
        standard: Duration.zero,
        page: Duration.zero,
        pageReverse: Duration.zero,
        enter: Curves.linear,
        exit: Curves.linear,
      );
    }
    return const AppMotion(
      fast: Duration(milliseconds: 140),
      standard: Duration(milliseconds: 240),
      page: Duration(milliseconds: 260),
      pageReverse: Duration(milliseconds: 220),
      enter: Curves.easeOutCubic,
      exit: Curves.easeInCubic,
    );
  }
}

/// Convenience extensions on [BuildContext] for accessing the active [VsCodeTheme].
extension ThemeExtensions on BuildContext {
  /// The active [VsCodeTheme] in the current widget tree.
  VsCodeTheme get vsCodeTheme =>
      Theme.of(this).extension<VsCodeThemeExtension>()?.theme ??
      BuiltinVsCodeThemes.kanagawaDragon;

  /// Direct accessor for theme colors throughout the application.
  VsCodeTheme get appColors => vsCodeTheme;

  /// Whether the active theme is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Shared motion tokens, resolved against the active motion preference.
  AppMotion get appMotion => AppMotion.resolve(
    disableAnimations: MediaQuery.disableAnimationsOf(this),
  );
}
