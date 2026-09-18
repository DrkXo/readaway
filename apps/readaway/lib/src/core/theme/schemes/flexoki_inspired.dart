import 'package:flutter/material.dart';

import '../theme.dart';

/// Light-mode [ColorScheme] for the Flexoki (Inspired) scheme.
const flexokiLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFBC5215), // orange-600
  onPrimary: Color(0xFFFFFCF0), // paper
  primaryContainer: Color(0xFFFED3AF), // orange-100
  onPrimaryContainer: Color(0xFF40200D), // orange-900
  secondary: Color(0xFF24837B), // cyan-600
  onSecondary: Color(0xFFFFFCF0), // paper
  secondaryContainer: Color(0xFFBFE8D9), // cyan-100
  onSecondaryContainer: Color(0xFF122F2C), // cyan-900
  tertiary: Color(0xFF5E409D), // purple-600
  onTertiary: Color(0xFFFFFCF0), // paper
  tertiaryContainer: Color(0xFFE2D9E9), // purple-100
  onTertiaryContainer: Color(0xFF261C39), // purple-900
  error: Color(0xFFAF3029), // red-600
  onError: Color(0xFFFFFCF0), // paper
  errorContainer: Color(0xFFFFCABB), // red-100
  onErrorContainer: Color(0xFF3E1715), // red-900
  surface: Color(0xFFFFFCF0), // paper
  onSurface: Color(0xFF100F0F), // black
  onSurfaceVariant: Color(0xFF6F6E69), // base-600
  outline: Color(0xFF878580), // base-500
  outlineVariant: Color(0xFFDAD8CE), // base-150
  shadow: Color(0xFF100F0F),
  scrim: Color(0xFF100F0F),
  inverseSurface: Color(0xFF1C1B1A), // base-950
  onInverseSurface: Color(0xFFFFFCF0), // paper
  surfaceTint: Color(0xFFBC5215),
  surfaceContainerLowest: Color(0xFFFFFCF0), // paper
  surfaceContainerLow: Color(0xFFF2F0E5), // base-50
  surfaceContainer: Color(0xFFE6E4D9), // base-100
  surfaceContainerHigh: Color(0xFFDAD8CE), // base-150
  surfaceContainerHighest: Color(0xFFCECDC3), // base-200
);

/// Light-mode [AppColors] tokens for the Flexoki (Inspired) scheme.
const flexokiLight = AppColors(
  scheme: flexokiLightScheme,
  readerBackground: Color(0xFFFFFCF0), // paper
  readerForeground: Color(0xFF100F0F), // black
  topbarBackground: Color(0xFFFFFCF0), // paper
  topbarForeground: Color(0xFF100F0F), // black
  bottombarBackground: Color(0xFFFFFCF0), // paper
  bottombarForeground: Color(0xFF100F0F), // black
  sheetBackground: Color(0xFFF2F0E5), // base-50
  sheetForeground: Color(0xFF100F0F), // black
  borderSubtle: Color(0xFFDAD8CE), // base-150
  borderStrong: Color(0xFFB7B5AC), // base-300
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  success: Color(0xFF66800B), // green-600
  onSuccess: Color(0xFFFFFCF0),
  warning: Color(0xFFAD8301), // yellow-600
  onWarning: Color(0xFFFFFCF0),
);

/// Dark-mode [ColorScheme] for the Flexoki (Inspired) scheme.
const flexokiDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFDA702C), // orange-400
  onPrimary: Color(0xFF100F0F), // black
  primaryContainer: Color(0xFF71320D), // orange-800
  onPrimaryContainer: Color(0xFFFED3AF), // orange-100
  secondary: Color(0xFF3AA99F), // cyan-400
  onSecondary: Color(0xFF100F0F), // black
  secondaryContainer: Color(0xFF164F4A), // cyan-800
  onSecondaryContainer: Color(0xFFBFE8D9), // cyan-100
  tertiary: Color(0xFF8B7EC8), // purple-400
  onTertiary: Color(0xFF100F0F), // black
  tertiaryContainer: Color(0xFF3C2A62), // purple-800
  onTertiaryContainer: Color(0xFFE2D9E9), // purple-100
  error: Color(0xFFD14D41), // red-400
  onError: Color(0xFF100F0F), // black
  errorContainer: Color(0xFF6C201C), // red-800
  onErrorContainer: Color(0xFFFFCABB), // red-100
  surface: Color(0xFF100F0F), // black
  onSurface: Color(0xFFCECDC3), // base-200
  onSurfaceVariant: Color(0xFF878580), // base-500
  outline: Color(0xFF575653), // base-700
  outlineVariant: Color(0xFF343331), // base-850
  shadow: Color(0xFF100F0F),
  scrim: Color(0xFF100F0F),
  inverseSurface: Color(0xFFCECDC3), // base-200
  onInverseSurface: Color(0xFF100F0F), // black
  surfaceTint: Color(0xFFDA702C),
  surfaceContainerLowest: Color(0xFF100F0F), // black
  surfaceContainerLow: Color(0xFF1C1B1A), // base-950
  surfaceContainer: Color(0xFF282726), // base-900
  surfaceContainerHigh: Color(0xFF343331), // base-850
  surfaceContainerHighest: Color(0xFF403E3C), // base-800
);

/// Dark-mode [AppColors] tokens for the Flexoki (Inspired) scheme.
const flexokiDark = AppColors(
  scheme: flexokiDarkScheme,
  readerBackground: Color(0xFF100F0F), // black
  readerForeground: Color(0xFFCECDC3), // base-200
  topbarBackground: Color(0xFF100F0F), // black
  topbarForeground: Color(0xFFCECDC3), // base-200
  bottombarBackground: Color(0xFF100F0F), // black
  bottombarForeground: Color(0xFFCECDC3), // base-200
  sheetBackground: Color(0xFF1C1B1A), // base-950
  sheetForeground: Color(0xFFCECDC3), // base-200
  borderSubtle: Color(0xFF343331), // base-850
  borderStrong: Color(0xFF575653), // base-700
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  success: Color(0xFF879A39), // green-400
  onSuccess: Color(0xFF100F0F),
  warning: Color(0xFFD0A215), // yellow-400
  onWarning: Color(0xFF100F0F),
);
