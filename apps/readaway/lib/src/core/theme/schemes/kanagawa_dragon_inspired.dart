import 'package:flutter/material.dart';

import '../theme.dart';

// ---------------------------------------------------------------------------
// Kanagawa Dragon — high-contrast dark variation based on Kanagawa
// ---------------------------------------------------------------------------

/// Light-mode [ColorScheme] for the Kanagawa Dragon (Inspired) scheme.
const kanagawaDragonLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF8A6534), // dragonYellow / ochre darkened for light bg
  onPrimary: Color(0xFFF6F4ED),
  primaryContainer: Color(0xFFE2DDD3),
  onPrimaryContainer: Color(0xFF181616),
  secondary: Color(0xFF466878), // dragonBlue2 darkened
  onSecondary: Color(0xFFF6F4ED),
  secondaryContainer: Color(0xFFD6E2E8),
  onSecondaryContainer: Color(0xFF181616),
  tertiary: Color(0xFF456B69), // dragonAqua darkened
  onTertiary: Color(0xFFF6F4ED),
  tertiaryContainer: Color(0xFFD3E4E2),
  onTertiaryContainer: Color(0xFF181616),
  error: Color(0xFFB54D48), // dragonRed
  onError: Color(0xFFF6F4ED),
  errorContainer: Color(0xFFFFD9D6),
  onErrorContainer: Color(0xFF181616),
  surface: Color(0xFFF6F4ED), // warm dragon light surface
  onSurface: Color(0xFF181616), // dragonBlack3
  onSurfaceVariant: Color(0xFF5A605A), // dragonAsh darkened
  outline: Color(0xFF7A7670),
  outlineVariant: Color(0xFFDFDBD2),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF181616),
  onInverseSurface: Color(0xFFF6F4ED),
  surfaceTint: Color(0xFF8A6534),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF0EDE4),
  surfaceContainer: Color(0xFFEBE7DD),
  surfaceContainerHigh: Color(0xFFE2DDD3),
  surfaceContainerHighest: Color(0xFFD8D2C6),
);

/// Light-mode [AppColors] tokens for the Kanagawa Dragon (Inspired) scheme.
const kanagawaDragonLight = AppColors(
  scheme: kanagawaDragonLightScheme,
  readerBackground: Color(0xFFF6F4ED),
  readerForeground: Color(0xFF181616),
  topbarBackground: Color(0xFFF6F4ED),
  topbarForeground: Color(0xFF181616),
  bottombarBackground: Color(0xFFEBE7DD),
  bottombarForeground: Color(0xFF5A605A),
  sheetBackground: Color(0xFFE2DDD3),
  sheetForeground: Color(0xFF181616),
  borderSubtle: Color(0xFFDFDBD2),
  borderStrong: Color(0xFF7A7670),
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  success: Color(0xFF4F6E45),
  onSuccess: Color(0xFFF6F4ED),
  warning: Color(0xFF9E651E),
  onWarning: Color(0xFFF6F4ED),
);

/// Dark-mode [ColorScheme] for the Kanagawa Dragon (Inspired) scheme.
const kanagawaDragonDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFC4B28A), // dragonYellow / carpYellow
  onPrimary: Color(0xFF181616), // dragonBlack3
  primaryContainer: Color(0xFF393836), // dragonBlack5
  onPrimaryContainer: Color(0xFFC5C9C5), // dragonWhite
  secondary: Color(0xFF8BA4B0), // dragonBlue2
  onSecondary: Color(0xFF181616),
  secondaryContainer: Color(0xFF223249), // dragonSelection
  onSecondaryContainer: Color(0xFFC5C9C5),
  tertiary: Color(0xFF8EA4A2), // dragonAqua
  onTertiary: Color(0xFF181616),
  tertiaryContainer: Color(0xFF2D4F67),
  onTertiaryContainer: Color(0xFFC5C9C5),
  error: Color(0xFFC4746E), // dragonRed
  onError: Color(0xFF181616),
  errorContainer: Color(0xFF6C201C),
  onErrorContainer: Color(0xFFFFCABB),
  surface: Color(0xFF181616), // dragonBlack3 (editor background)
  onSurface: Color(0xFFC5C9C5), // dragonWhite
  onSurfaceVariant: Color(0xFF737C73), // dragonAsh
  outline: Color(0xFF625E5A), // dragonBlack6
  outlineVariant: Color(0xFF282727), // dragonBlack4
  shadow: Color(0xFF0D0C0C),
  scrim: Color(0xFF0D0C0C),
  inverseSurface: Color(0xFFC5C9C5),
  onInverseSurface: Color(0xFF181616),
  surfaceTint: Color(0xFFC4B28A),
  surfaceContainerLowest: Color(0xFF0D0C0C), // dragonBlack0
  surfaceContainerLow: Color(0xFF12120F), // dragonBlack1
  surfaceContainer: Color(0xFF181616), // dragonBlack3
  surfaceContainerHigh: Color(0xFF282727), // dragonBlack4
  surfaceContainerHighest: Color(0xFF393836), // dragonBlack5
);

/// Dark-mode [AppColors] tokens for the Kanagawa Dragon (Inspired) scheme.
const kanagawaDragonDark = AppColors(
  scheme: kanagawaDragonDarkScheme,
  readerBackground: Color(0xFF181616), // dragonBlack3
  readerForeground: Color(0xFFC5C9C5), // dragonWhite
  topbarBackground: Color(0xFF181616), // dragonBlack3
  topbarForeground: Color(0xFFC5C9C5), // dragonWhite
  bottombarBackground: Color(0xFF12120F), // dragonBlack1
  bottombarForeground: Color(0xFFC8C093), // dragonYellow
  sheetBackground: Color(0xFF1D1C19), // dragonBlack2
  sheetForeground: Color(0xFFC5C9C5), // dragonWhite
  borderSubtle: Color(0xFF282727), // dragonBlack4
  borderStrong: Color(0xFF625E5A), // dragonBlack6
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  success: Color(0xFF8A9A7B), // dragonGreen2
  onSuccess: Color(0xFF181616),
  warning: Color(0xFFFF9E3B), // dragonOrange
  onWarning: Color(0xFF181616),
);
