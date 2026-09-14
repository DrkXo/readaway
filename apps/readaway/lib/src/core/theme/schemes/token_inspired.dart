import 'package:flutter/material.dart';

import '../theme.dart';

// ---------------------------------------------------------------------------
// Token (Inspired) — the built-in color scheme
//
// Each scheme lives in its own file under `schemes/` and is registered in
// `ThemeSchemes.all` (see theme_scheme.dart). A scheme bundles a light and a
// dark palette; the app applies the light variant in light mode and the dark
// variant in dark mode.
// ---------------------------------------------------------------------------

/// Light-mode [ColorScheme] for the Token (Inspired) scheme.
const tokenInspiredLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF9A4929),
  onPrimary: Color(0xFFFAF9F5),
  primaryContainer: Color(0xFFDDDCD6),
  onPrimaryContainer: Color(0xFF2A2920),
  secondary: Color(0xFF876032),
  onSecondary: Color(0xFFFAF9F5),
  secondaryContainer: Color(0xFFEAE9E5),
  onSecondaryContainer: Color(0xFF2A2920),
  tertiary: Color(0xFF527594),
  onTertiary: Color(0xFFFAF9F5),
  tertiaryContainer: Color(0xFFDAE4F2),
  onTertiaryContainer: Color(0xFF2A2920),
  error: Color(0xFFB05555),
  onError: Color(0xFFFAF9F5),
  errorContainer: Color(0xFFFFDADA),
  onErrorContainer: Color(0xFF2A2920),
  surface: Color(0xFFFAF9F5),
  onSurface: Color(0xFF2A2920),
  onSurfaceVariant: Color(0xFF3D3929),
  outline: Color(0xFF858179),
  outlineVariant: Color(0xFFE0DDD8),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2A2920),
  onInverseSurface: Color(0xFFFAF9F5),
  surfaceTint: Color(0xFF9A4929),
  surfaceContainerLowest: Color(0xFFFAF9F5),
  surfaceContainerLow: Color(0xFFFAF9F5),
  surfaceContainer: Color(0xFFECEBE7),
  surfaceContainerHigh: Color(0xFFF6F5F1),
  surfaceContainerHighest: Color(0xFFF0EFEB),
);

/// Light-mode [AppColors] tokens for the Token (Inspired) scheme.
const tokenInspiredLight = AppColors(
  scheme: tokenInspiredLightScheme,
  readerBackground: Color(0xFFFAF9F5),
  readerForeground: Color(0xFF2A2920),
  shadowSm: [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ],
  shadowMd: [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ],
  shadowLg: [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ],
  success: Color(0xFF2E6C38),
  onSuccess: Color(0xFFFAF9F5),
  warning: Color(0xFF8B5A00),
  onWarning: Color(0xFFFAF9F5),
);

/// Dark-mode [ColorScheme] for the Token (Inspired) scheme.
const tokenInspiredDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFD97757),
  onPrimary: Color(0xFF191918),
  primaryContainer: Color(0xFF3A3A37),
  onPrimaryContainer: Color(0xFFE8E4DC),
  secondary: Color(0xFFC4956A),
  onSecondary: Color(0xFF191918),
  secondaryContainer: Color(0xFF383835),
  onSecondaryContainer: Color(0xFFE8E4DC),
  tertiary: Color(0xFF7B9EBD),
  onTertiary: Color(0xFF191918),
  tertiaryContainer: Color(0xFF1E2634),
  onTertiaryContainer: Color(0xFFE8E4DC),
  error: Color(0xFFC67777),
  onError: Color(0xFF191918),
  errorContainer: Color(0xFF3C2024),
  onErrorContainer: Color(0xFFE8E4DC),
  surface: Color(0xFF262624),
  onSurface: Color(0xFFE8E4DC),
  onSurfaceVariant: Color(0xFFD4CFC6),
  outline: Color(0xFF5A5955),
  outlineVariant: Color(0xFF333330),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE8E4DC),
  onInverseSurface: Color(0xFF262624),
  surfaceTint: Color(0xFFD97757),
  surfaceContainerLowest: Color(0xFF191918),
  surfaceContainerLow: Color(0xFF1D1D1C),
  surfaceContainer: Color(0xFF212120),
  surfaceContainerHigh: Color(0xFF2F2F2D),
  surfaceContainerHighest: Color(0xFF383835),
);

/// Dark-mode [AppColors] tokens for the Token (Inspired) scheme.
const tokenInspiredDark = AppColors(
  scheme: tokenInspiredDarkScheme,
  readerBackground: Color(0xFF262624),
  readerForeground: Color(0xFFE8E4DC),
  shadowSm: [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ],
  shadowMd: [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ],
  shadowLg: [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ],
  success: Color(0xFF7CD98A),
  onSuccess: Color(0xFF191918),
  warning: Color(0xFFFFBA38),
  onWarning: Color(0xFF191918),
);
