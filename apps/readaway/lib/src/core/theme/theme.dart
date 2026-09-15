library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'theme.tailor.dart';

extension ThemeExtensions on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// ---------------------------------------------------------------------------
// Custom lerp encoders for types theme_tailor doesn't handle by default
// ---------------------------------------------------------------------------

/// Lerps [ColorScheme] values.
class ColorSchemeEncoder extends ThemeEncoder<ColorScheme> {
  const ColorSchemeEncoder();

  @override
  ColorScheme lerp(ColorScheme a, ColorScheme b, double t) =>
      ColorScheme.lerp(a, b, t);
}

/// Lerps [List]s of [BoxShadow].
class BoxShadowListEncoder extends ThemeEncoder<List<BoxShadow>> {
  const BoxShadowListEncoder();

  @override
  List<BoxShadow> lerp(List<BoxShadow> a, List<BoxShadow> b, double t) =>
      BoxShadow.lerpList(a, b, t)!;
}

// ---------------------------------------------------------------------------
// AppColors — single source of truth for all colors + shadows
// ---------------------------------------------------------------------------

@TailorMixin(
  themeGetter: ThemeGetter.none,
  encoders: [ColorSchemeEncoder(), BoxShadowListEncoder()],
)
class AppColors extends ThemeExtension<AppColors>
    with DiagnosticableTreeMixin, _$AppColorsTailorMixin {
  const AppColors({
    required this.scheme,
    required this.readerBackground,
    required this.readerForeground,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  @override
  final ColorScheme scheme;
  @override
  final Color readerBackground;
  @override
  final Color readerForeground;
  @override
  final List<BoxShadow> shadowSm;
  @override
  final List<BoxShadow> shadowMd;
  @override
  final List<BoxShadow> shadowLg;
  @override
  final Color success;
  @override
  final Color onSuccess;
  @override
  final Color warning;
  @override
  final Color onWarning;
}

