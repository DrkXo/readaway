library;

import 'package:flutter/material.dart';
import 'package:readaway_core/readaway_core.dart';

export 'package:readaway_core/readaway_core.dart'
    show VsCodeTheme, VsCodeThemeColorX, BuiltinVsCodeThemes;

/// Convenient alias mapping legacy [AppColors] to [VsCodeTheme].
typedef AppColors = VsCodeTheme;

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
}
