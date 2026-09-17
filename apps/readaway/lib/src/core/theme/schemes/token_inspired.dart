import 'package:flutter/material.dart';

import '../theme.dart';

// ---------------------------------------------------------------------------
// Token — authentic color scheme based on Thorsten Rhau's Token palette
//
// Background ramp:
//   bg0: Recessed floating windows / popups / sheets
//   bg1: Secondary menus, status lines, bottom bars, panels
//   bg2: Inactive gutters, tabs, inactive chrome
//   bg3: Primary editor / reader background
//   bg4: Raised cursor lines, separators, borders
//   bg5: Strong raised active selections, quickfix
//
// Foreground ramp:
//   fg0: Primary text / Normal
//   fg1: Secondary text / emphasized UI / status line text
//   fg2: Muted comments / secondary UI text
//   fg3: Subdued borders / nonessential text
// ---------------------------------------------------------------------------

/// Light-mode [ColorScheme] for the Token scheme.
const tokenInspiredLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF863716), // accent (orange)
  onPrimary: Color(0xFFFAF9F5), // bg3
  primaryContainer: Color(0xFFDDDCD6), // sel
  onPrimaryContainer: Color(0xFF323128), // fg0
  secondary: Color(0xFF6D4717), // accent2 (ochre)
  onSecondary: Color(0xFFFAF9F5), // bg3
  secondaryContainer: Color(0xFFEAE9E5), // bg5
  onSecondaryContainer: Color(0xFF323128), // fg0
  tertiary: Color(0xFF315270), // blue
  onTertiary: Color(0xFFFAF9F5), // bg3
  tertiaryContainer: Color(0xFFDAE4F2), // diag_info
  onTertiaryContainer: Color(0xFF323128), // fg0
  error: Color(0xFFAD5253), // red
  onError: Color(0xFFFAF9F5), // bg3
  errorContainer: Color(0xFFFFDADA), // diag_error
  onErrorContainer: Color(0xFF323128), // fg0
  surface: Color(0xFFFAF9F5), // bg3
  onSurface: Color(0xFF323128), // fg0
  onSurfaceVariant: Color(0xFF504B44), // fg2
  outline: Color(0xFF524E46), // fg3
  outlineVariant: Color(0xFFF0EFEB), // bg4
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF323128), // fg0
  onInverseSurface: Color(0xFFFAF9F5), // bg3
  surfaceTint: Color(0xFF863716),
  surfaceContainerLowest: Color(0xFFFAF9F5), // bg3
  surfaceContainerLow: Color(0xFFF6F5F1), // bg2
  surfaceContainer: Color(0xFFECEBE7), // bg1
  surfaceContainerHigh: Color(0xFFEAE9E5), // bg5
  surfaceContainerHighest: Color(0xFFDDDCD6), // sel
);

/// Light-mode [AppColors] tokens for the Token scheme.
const tokenInspiredLight = AppColors(
  scheme: tokenInspiredLightScheme,
  readerBackground: Color(0xFFFAF9F5), // bg3 (primary editor)
  readerForeground: Color(0xFF323128), // fg0
  topbarBackground: Color(0xFFFAF9F5), // bg3
  topbarForeground: Color(0xFF323128), // fg0
  bottombarBackground: Color(0xFFECEBE7), // bg1
  bottombarForeground: Color(0xFF565141), // fg1
  sheetBackground: Color(0xFFE6E5E1), // bg0 (floating sheet/popover)
  sheetForeground: Color(0xFF323128), // fg0
  borderSubtle: Color(0xFFF0EFEB), // bg4
  borderStrong: Color(0xFF524E46), // fg3
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  success: Color(0xFF365A33), // green
  onSuccess: Color(0xFFFAF9F5),
  warning: Color(0xFF857238), // yellow
  onWarning: Color(0xFFFAF9F5),
);

/// Dark-mode [ColorScheme] for the Token scheme.
const tokenInspiredDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFF4906F), // accent (orange)
  onPrimary: Color(0xFF191918), // bg0
  primaryContainer: Color(0xFF3A3A37), // sel
  onPrimaryContainer: Color(0xFFC3C0B8), // fg0
  secondary: Color(0xFFF7C699), // accent2 (ochre)
  onSecondary: Color(0xFF191918), // bg0
  secondaryContainer: Color(0xFF383835), // bg5
  onSecondaryContainer: Color(0xFFC3C0B8), // fg0
  tertiary: Color(0xFF81A5C4), // blue
  onTertiary: Color(0xFF191918), // bg0
  tertiaryContainer: Color(0xFF1E2634), // diag_info
  onTertiaryContainer: Color(0xFFC3C0B8), // fg0
  error: Color(0xFFD68585), // red
  onError: Color(0xFF191918), // bg0
  errorContainer: Color(0xFF3C2024), // diag_error
  onErrorContainer: Color(0xFFC3C0B8), // fg0
  surface: Color(0xFF262624), // bg3
  onSurface: Color(0xFFC3C0B8), // fg0
  onSurfaceVariant: Color(0xFFA19C94), // fg2
  outline: Color(0xFF8A8884), // fg3
  outlineVariant: Color(0xFF2F2F2D), // bg4
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFC3C0B8), // fg0
  onInverseSurface: Color(0xFF262624), // bg3
  surfaceTint: Color(0xFFF4906F),
  surfaceContainerLowest: Color(0xFF191918), // bg0
  surfaceContainerLow: Color(0xFF1D1D1C), // bg1
  surfaceContainer: Color(0xFF212120), // bg2
  surfaceContainerHigh: Color(0xFF2F2F2D), // bg4
  surfaceContainerHighest: Color(0xFF383835), // bg5
);

/// Dark-mode [AppColors] tokens for the Token scheme.
const tokenInspiredDark = AppColors(
  scheme: tokenInspiredDarkScheme,
  readerBackground: Color(0xFF262624), // bg3 (primary editor)
  readerForeground: Color(0xFFC3C0B8), // fg0
  topbarBackground: Color(0xFF262624), // bg3
  topbarForeground: Color(0xFFC3C0B8), // fg0
  bottombarBackground: Color(0xFF1D1D1C), // bg1
  bottombarForeground: Color(0xFFA6A198), // fg1
  sheetBackground: Color(0xFF191918), // bg0 (floating sheet/popover)
  sheetForeground: Color(0xFFC3C0B8), // fg0
  borderSubtle: Color(0xFF2F2F2D), // bg4
  borderStrong: Color(0xFF8A8884), // fg3
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  success: Color(0xFF8FB78C), // green
  onSuccess: Color(0xFF191918),
  warning: Color(0xFFB99D4A), // yellow
  onWarning: Color(0xFF191918),
);
