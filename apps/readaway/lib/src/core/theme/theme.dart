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
// AppColors — single source of truth for all semantic colors and chrome tokens
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
    required this.topbarBackground,
    required this.topbarForeground,
    required this.bottombarBackground,
    required this.bottombarForeground,
    required this.sheetBackground,
    required this.sheetForeground,
    required this.borderSubtle,
    required this.borderStrong,
    this.shadowSm = const [],
    this.shadowMd = const [],
    this.shadowLg = const [],
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  @override
  final ColorScheme scheme;

  /// Document reading viewport background canvas.
  @override
  final Color readerBackground;

  /// Document reading text color.
  @override
  final Color readerForeground;

  /// Top app bar and reader header background.
  @override
  final Color topbarBackground;

  /// Top app bar text and icon color.
  @override
  final Color topbarForeground;

  /// Bottom bar and reader toolbar navigation background.
  @override
  final Color bottombarBackground;

  /// Bottom bar icon and text color.
  @override
  final Color bottombarForeground;

  /// Floating sheet, popover, and dialog background.
  @override
  final Color sheetBackground;

  /// Floating sheet text and content foreground.
  @override
  final Color sheetForeground;

  /// Subtle 1px surface boundary / separator color.
  @override
  final Color borderSubtle;

  /// Strong / high-contrast outline border color.
  @override
  final Color borderStrong;

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

