library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway/src/core/app_assets.dart';

part 'app_theme.dart';

@module
abstract class ThemeModule {
  @lazySingleton
  AppColors get appColors => AppColors.light;
}

extension ThemeExtensions on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// ---------------------------------------------------------------------------
// AppColors — single source of truth for all colors + shadows
// ---------------------------------------------------------------------------

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.scheme,
    required this.readerBackground,
    required this.readerForeground,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  final ColorScheme scheme;
  final Color readerBackground;
  final Color readerForeground;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;

  // Light ------------------------------------------------------------------

  static const lightScheme = ColorScheme(
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

  static const light = AppColors(
    scheme: lightScheme,
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
  );

  // Dark -------------------------------------------------------------------

  static const darkScheme = ColorScheme(
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

  static const dark = AppColors(
    scheme: darkScheme,
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
  );

  // ThemeExtension ---------------------------------------------------------

  @override
  AppColors copyWith({
    ColorScheme? scheme,
    Color? readerBackground,
    Color? readerForeground,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
  }) {
    return AppColors(
      scheme: scheme ?? this.scheme,
      readerBackground: readerBackground ?? this.readerBackground,
      readerForeground: readerForeground ?? this.readerForeground,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scheme: ColorScheme.lerp(scheme, other.scheme, t),
      readerBackground: Color.lerp(
        readerBackground,
        other.readerBackground,
        t,
      )!,
      readerForeground: Color.lerp(
        readerForeground,
        other.readerForeground,
        t,
      )!,
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// TactileReaderBackground — GPU shader paper/slate texture
// ---------------------------------------------------------------------------

class TactileReaderBackground extends StatelessWidget {
  const TactileReaderBackground({
    super.key,
    required this.appColors,
    required this.child,
  });

  final AppColors appColors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      (context, shader, child) {
        return _TactileSurface(
          shader: shader,
          appColors: appColors,
          child: child!,
        );
      },
      assetKey: AppShaders.tactileSurface,
      child: child,
    );
  }
}

class _TactileSurface extends StatelessWidget {
  const _TactileSurface({
    required this.shader,
    required this.appColors,
    required this.child,
  });

  final ui.FragmentShader shader;
  final AppColors appColors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SurfacePainter(shader: shader, appColors: appColors),
      child: child,
    );
  }
}

class _SurfacePainter extends CustomPainter {
  _SurfacePainter({
    required this.shader,
    required this.appColors,
  });

  final ui.FragmentShader shader;
  final AppColors appColors;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = appColors.readerBackground;
    final isDark = appColors.scheme.brightness == Brightness.dark;

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, isDark ? 1.0 : 0.0);
    shader.setFloat(3, baseColor.r);
    shader.setFloat(4, baseColor.g);
    shader.setFloat(5, baseColor.b);
    shader.setFloat(6, 1.0);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _SurfacePainter oldDelegate) {
    return oldDelegate.appColors.scheme.brightness !=
        appColors.scheme.brightness;
  }
}

// ---------------------------------------------------------------------------
// Reader typography
// ---------------------------------------------------------------------------

TextStyle readerTextStyle({
  required AppColors appColors,
  String fontFamily = 'Roboto',
  double fontSize = 18.0,
  double height = 1.75,
  double letterSpacing = -0.2,
}) {
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    height: height,
    letterSpacing: letterSpacing,
    color: appColors.readerForeground,
    leadingDistribution: TextLeadingDistribution.even,
  );
}
