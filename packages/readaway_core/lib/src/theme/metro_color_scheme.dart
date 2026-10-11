import 'package:flutter/material.dart';
import 'package:vscode_theme_parser/vscode_theme_parser.dart';

/// Clean, semantic color scheme designed for Readaway's Metro design language.
///
/// Encapsulates reader canvas, chrome, panel surfaces, inputs, accents, and
/// feedback states into lightweight, compile-time `const` tokens.
///
/// Can be converted to a [VsCodeTheme] via [toVsCodeTheme] or a Flutter
/// [ColorScheme] via [toColorScheme] for interoperability with existing
/// [VsCodeThemeColorX] extensions and Material 3 widgets.
@immutable
class MetroColorScheme {
  const MetroColorScheme({
    required this.name,
    required this.brightness,
    required this.readerBackground,
    required this.readerForeground,
    required this.chromeBackground,
    required this.chromeForeground,
    required this.chromeBorder,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.panelBorder,
    required this.inputBackground,
    required this.inputForeground,
    required this.inputBorder,
    required this.accent,
    required this.onAccent,
    required this.accentSecondary,
    required this.onAccentSecondary,
    required this.selection,
    required this.borderSubtle,
    required this.borderStrong,
    this.titleBarBackground,
    this.statusBarBackground,
    this.statusBarForeground,
    this.error = const Color(0xFFD14D41),
    this.onError = Colors.white,
    this.warning = const Color(0xFFD0A215),
    this.onWarning = const Color(0xFF100F0F),
    this.success = const Color(0xFF879A39),
    this.onSuccess = const Color(0xFF100F0F),
  });

  /// Name of the scheme (e.g., 'Token Dark Inspired').
  final String name;

  /// Whether this is a dark or light color scheme.
  final Brightness brightness;

  /// Reader viewport and main background canvas.
  final Color readerBackground;

  /// Reader body text and primary foreground color.
  final Color readerForeground;

  /// Chrome bars (Title bar, Navigation bar, Status bar) background.
  final Color chromeBackground;

  /// Chrome bars foreground (icons, titles).
  final Color chromeForeground;

  /// Subtle border for chrome bars.
  final Color chromeBorder;

  /// Optional custom title bar background (defaults to [chromeBackground]).
  final Color? titleBarBackground;

  /// Optional custom status bar background (defaults to [chromeBackground]).
  final Color? statusBarBackground;

  /// Optional custom status bar foreground (defaults to [chromeForeground]).
  final Color? statusBarForeground;

  /// Panel and container surface background (sheets, drawers, sidebars).
  final Color surface;

  /// Recessed surface background (lower elevation or inactive tab/gutter).
  final Color surfaceLow;

  /// Elevated surface background (menus, popovers, quick picks).
  final Color surfaceHigh;

  /// Border for panels, sheets, and dialogs.
  final Color panelBorder;

  /// Input fields and text boxes background.
  final Color inputBackground;

  /// Input fields text and icon color.
  final Color inputForeground;

  /// Input fields border.
  final Color inputBorder;

  /// Primary accent color (Metro tiles, active pivot indicator, primary CTA).
  final Color accent;

  /// Foreground on primary accent (e.g. white or dark text on accent CTA).
  final Color onAccent;

  /// Secondary accent / container color (badges, secondary buttons).
  final Color accentSecondary;

  /// Foreground on secondary accent.
  final Color onAccentSecondary;

  /// Active text / item selection highlight color.
  final Color selection;

  /// Subtle divider and indent guide border.
  final Color borderSubtle;

  /// Strong outline and focus border.
  final Color borderStrong;

  /// Semantic error state color.
  final Color error;

  /// Foreground color on error state.
  final Color onError;

  /// Semantic warning state color.
  final Color warning;

  /// Foreground color on warning state.
  final Color onWarning;

  /// Semantic success state color.
  final Color success;

  /// Foreground color on success state.
  final Color onSuccess;

  /// Whether the scheme is dark mode.
  bool get isDark => brightness == Brightness.dark;

  /// Converts this [MetroColorScheme] into a trimmed, lightweight [VsCodeTheme]
  /// containing only the UI keys consumed by [VsCodeThemeColorX].
  VsCodeTheme toVsCodeTheme() {
    return VsCodeTheme(
      name: name,
      type: isDark ? 'dark' : 'light',
      colors: toVsCodeColorMap(),
    );
  }

  /// Converts this [MetroColorScheme] into a map of standard VS Code color keys.
  Map<String, String> toVsCodeColorMap() {
    String hex(Color c) {
      final a = (c.a * 255).round().toRadixString(16).padLeft(2, '0');
      final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
      return a.toUpperCase() == 'FF'
          ? '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}'
          : '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}${a.toUpperCase()}';
    }

    return {
      'editor.background': hex(readerBackground),
      'editor.foreground': hex(readerForeground),
      'editor.selectionBackground': hex(selection),
      'editor.selectionHighlightBackground': hex(selection),
      'editor.lineHighlightBackground': hex(surfaceLow),
      'titleBar.activeBackground': hex(titleBarBackground ?? chromeBackground),
      'titleBar.activeForeground': hex(chromeForeground),
      'titleBar.inactiveBackground': hex(surfaceLow),
      'titleBar.inactiveForeground': hex(
        chromeForeground.withValues(alpha: 0.6),
      ),
      'titleBar.border': hex(chromeBorder),
      'statusBar.background': hex(statusBarBackground ?? chromeBackground),
      'statusBar.foreground': hex(statusBarForeground ?? chromeForeground),
      'statusBar.border': hex(chromeBorder),
      'activityBar.background': hex(chromeBackground),
      'activityBar.foreground': hex(chromeForeground),
      'activityBar.border': hex(chromeBorder),
      'activityBarBadge.background': hex(accent),
      'activityBarBadge.foreground': hex(onAccent),
      'sideBar.background': hex(surface),
      'sideBar.foreground': hex(readerForeground),
      'sideBar.border': hex(panelBorder),
      'sideBarTitle.foreground': hex(readerForeground),
      'sideBarSectionHeader.background': hex(surfaceLow),
      'sideBarSectionHeader.foreground': hex(readerForeground),
      'panel.background': hex(surface),
      'panel.border': hex(panelBorder),
      'editorWidget.background': hex(surfaceHigh),
      'editorWidget.border': hex(panelBorder),
      'editorWidget.foreground': hex(readerForeground),
      'input.background': hex(inputBackground),
      'input.foreground': hex(inputForeground),
      'input.border': hex(inputBorder),
      'input.placeholderForeground': hex(
        readerForeground.withValues(alpha: 0.5),
      ),
      'inputOption.activeBackground': hex(accentSecondary),
      'inputOption.activeBorder': hex(borderStrong),
      'dropdown.background': hex(inputBackground),
      'dropdown.foreground': hex(inputForeground),
      'dropdown.border': hex(inputBorder),
      'dropdown.listBackground': hex(surfaceHigh),
      'menu.background': hex(surfaceHigh),
      'menu.foreground': hex(readerForeground),
      'menu.selectionBackground': hex(selection),
      'menu.selectionForeground': hex(readerForeground),
      'menu.border': hex(borderSubtle),
      'badge.background': hex(accent),
      'badge.foreground': hex(onAccent),
      'button.background': hex(accent),
      'button.foreground': hex(onAccent),
      'button.secondaryBackground': hex(accentSecondary),
      'button.secondaryForeground': hex(onAccentSecondary),
      'list.hoverBackground': hex(surfaceLow),
      'list.hoverForeground': hex(readerForeground),
      'list.activeSelectionBackground': hex(selection),
      'list.activeSelectionForeground': hex(readerForeground),
      'list.inactiveSelectionBackground': hex(selection),
      'list.inactiveSelectionForeground': hex(readerForeground),
      'notifications.background': hex(surfaceHigh),
      'notifications.foreground': hex(readerForeground),
      'notifications.border': hex(panelBorder),
      'focusBorder': hex(borderStrong),
      'errorForeground': hex(error),
      'editorError.foreground': hex(error),
      'editorWarning.foreground': hex(warning),
      'editorIndentGuide.background1': hex(borderSubtle),
      'editorIndentGuide.activeBackground1': hex(borderStrong),
    };
  }

  /// Converts this [MetroColorScheme] to a Flutter Material 3 [ColorScheme].
  ColorScheme toColorScheme() {
    if (isDark) {
      return ColorScheme.dark(
        primary: accent,
        onPrimary: onAccent,
        primaryContainer: accentSecondary,
        onPrimaryContainer: onAccentSecondary,
        secondary: accentSecondary,
        onSecondary: onAccentSecondary,
        surface: surface,
        onSurface: readerForeground,
        surfaceContainerLowest: readerBackground,
        surfaceContainerLow: surfaceLow,
        surfaceContainer: surface,
        surfaceContainerHigh: surfaceHigh,
        surfaceContainerHighest: inputBackground,
        onSurfaceVariant: readerForeground.withValues(alpha: 0.7),
        error: error,
        onError: onError,
        outline: borderSubtle,
        outlineVariant: borderStrong,
      );
    } else {
      return ColorScheme.light(
        primary: accent,
        onPrimary: onAccent,
        primaryContainer: accentSecondary,
        onPrimaryContainer: onAccentSecondary,
        secondary: accentSecondary,
        onSecondary: onAccentSecondary,
        surface: surface,
        onSurface: readerForeground,
        surfaceContainerLowest: readerBackground,
        surfaceContainerLow: surfaceLow,
        surfaceContainer: surface,
        surfaceContainerHigh: surfaceHigh,
        surfaceContainerHighest: inputBackground,
        onSurfaceVariant: readerForeground.withValues(alpha: 0.7),
        error: error,
        onError: onError,
        outline: borderSubtle,
        outlineVariant: borderStrong,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Built-in Inspired Metro Color Schemes
  // ---------------------------------------------------------------------------

  /// Flexoki Dark Inspired.
  static const flexokiDarkInspired = MetroColorScheme(
    name: 'Flexoki Dark Inspired',
    brightness: Brightness.dark,
    readerBackground: Color(0xFF100F0F),
    readerForeground: Color(0xFFCECDC3),
    chromeBackground: Color(0xFF100F0F),
    chromeForeground: Color(0xFFCECDC3),
    chromeBorder: Color(0xFF343331),
    surface: Color(0xFF100F0F),
    surfaceLow: Color(0xFF1C1B1A),
    surfaceHigh: Color(0xFF282726),
    panelBorder: Color(0xFF343331),
    inputBackground: Color(0xFF1C1B1A),
    inputForeground: Color(0xFFCECDC3),
    inputBorder: Color(0xFF343331),
    accent: Color(0xFF3AA99F),
    onAccent: Color(0xFF100F0F),
    accentSecondary: Color(0xFF403E3C),
    onAccentSecondary: Color(0xFFCECDC3),
    selection: Color(0x33CECDC3),
    borderSubtle: Color(0xFF343331),
    borderStrong: Color(0xFF403E3C),
    error: Color(0xFFD14D41),
    warning: Color(0xFFDA702C),
    success: Color(0xFF879A39),
  );

  /// Flexoki Light Inspired.
  static const flexokiLightInspired = MetroColorScheme(
    name: 'Flexoki Light Inspired',
    brightness: Brightness.light,
    readerBackground: Color(0xFFFFFCF0),
    readerForeground: Color(0xFF100F0F),
    chromeBackground: Color(0xFFFFFCF0),
    chromeForeground: Color(0xFF100F0F),
    chromeBorder: Color(0xFFDAD8CE),
    surface: Color(0xFFFFFCF0),
    surfaceLow: Color(0xFFF2F0E5),
    surfaceHigh: Color(0xFFE6E4D9),
    panelBorder: Color(0xFFDAD8CE),
    inputBackground: Color(0xFFF2F0E5),
    inputForeground: Color(0xFF100F0F),
    inputBorder: Color(0xFFDAD8CE),
    accent: Color(0xFF24837B),
    onAccent: Color(0xFFFFFCF0),
    accentSecondary: Color(0xFFCECDC3),
    onAccentSecondary: Color(0xFF100F0F),
    selection: Color(0x44100F0F),
    borderSubtle: Color(0xFFDAD8CE),
    borderStrong: Color(0xFFCECDC3),
    error: Color(0xFFAF3029),
    warning: Color(0xFFBC5215),
    success: Color(0xFF66800B),
  );

  /// Kanagawa Dragon Inspired.
  static const kanagawaDragonInspired = MetroColorScheme(
    name: 'Kanagawa Dragon Inspired',
    brightness: Brightness.dark,
    readerBackground: Color(0xFF181616),
    readerForeground: Color(0xFFC5C9C5),
    chromeBackground: Color(0xFF393836),
    chromeForeground: Color(0xFFC5C9C5),
    titleBarBackground: Color(0xFF393836),
    statusBarBackground: Color(0xFF0D0C0C),
    statusBarForeground: Color(0xFFC8C093),
    chromeBorder: Color(0xFF282727),
    surface: Color(0xFF181616),
    surfaceLow: Color(0xFF282727),
    surfaceHigh: Color(0xFF393836),
    panelBorder: Color(0xFF0D0C0C),
    inputBackground: Color(0xFF0D0C0C),
    inputForeground: Color(0xFFC5C9C5),
    inputBorder: Color(0xFF223249),
    accent: Color(0xFF658594),
    onAccent: Color(0xFF181616),
    accentSecondary: Color(0xFF223249),
    onAccentSecondary: Color(0xFFC5C9C5),
    selection: Color(0xFF223249),
    borderSubtle: Color(0xFF282727),
    borderStrong: Color(0xFF393836),
    error: Color(0xFFE82424),
    warning: Color(0xFFFF9E3B),
    success: Color(0xFF76946A),
  );

  /// Kanagawa Wave Inspired.
  static const kanagawaWaveInspired = MetroColorScheme(
    name: 'Kanagawa Wave Inspired',
    brightness: Brightness.dark,
    readerBackground: Color(0xFF1F1F28),
    readerForeground: Color(0xFFDCD7BA),
    chromeBackground: Color(0xFF16161D),
    chromeForeground: Color(0xFFDCD7BA),
    titleBarBackground: Color(0xFF363646),
    statusBarBackground: Color(0xFF16161D),
    statusBarForeground: Color(0xFFC8C093),
    chromeBorder: Color(0xFF2A2A37),
    surface: Color(0xFF1F1F28),
    surfaceLow: Color(0xFF2A2A37),
    surfaceHigh: Color(0xFF363646),
    panelBorder: Color(0xFF16161D),
    inputBackground: Color(0xFF16161D),
    inputForeground: Color(0xFFDCD7BA),
    inputBorder: Color(0xFF223249),
    accent: Color(0xFF7E9CD8),
    onAccent: Color(0xFF1F1F28),
    accentSecondary: Color(0xFF223249),
    onAccentSecondary: Color(0xFFDCD7BA),
    selection: Color(0xFF223249),
    borderSubtle: Color(0xFF2A2A37),
    borderStrong: Color(0xFF363646),
    error: Color(0xFFE82424),
    warning: Color(0xFFFF9E3B),
    success: Color(0xFF76946A),
  );

  /// Kanagawa Lotus Inspired.
  static const kanagawaLotusInspired = MetroColorScheme(
    name: 'Kanagawa Lotus Inspired',
    brightness: Brightness.light,
    readerBackground: Color(0xFFF2ECBC),
    readerForeground: Color(0xFF545464),
    chromeBackground: Color(0xFFD5CEA3),
    chromeForeground: Color(0xFF545464),
    titleBarBackground: Color(0xFFE4D794),
    statusBarBackground: Color(0xFFD5CEA3),
    statusBarForeground: Color(0xFF43436C),
    chromeBorder: Color(0xFFC7D7E0),
    surface: Color(0xFFF2ECBC),
    surfaceLow: Color(0xFFE7DBA0),
    surfaceHigh: Color(0xFFE4D794),
    panelBorder: Color(0xFFD5CEA3),
    inputBackground: Color(0xFFD5CEA3),
    inputForeground: Color(0xFF545464),
    inputBorder: Color(0xFFC7D7E0),
    accent: Color(0xFF5A7785),
    onAccent: Color(0xFFF2ECBC),
    accentSecondary: Color(0xFFC7D7E0),
    onAccentSecondary: Color(0xFF545464),
    selection: Color(0xFFC7D7E0),
    borderSubtle: Color(0xFFE7DBA0),
    borderStrong: Color(0xFFE4D794),
    error: Color(0xFFE82424),
    warning: Color(0xFFE98A00),
    success: Color(0xFF6E915F),
  );

  /// Token Dark Inspired.
  static const tokenDarkInspired = MetroColorScheme(
    name: 'Token Dark Inspired',
    brightness: Brightness.dark,
    readerBackground: Color(0xFF262624),
    readerForeground: Color(0xFFC3C0B8),
    chromeBackground: Color(0xFF212120),
    chromeForeground: Color(0xFFC3C0B8),
    chromeBorder: Color(0xFF383835),
    surface: Color(0xFF212120),
    surfaceLow: Color(0xFF2F2F2D),
    surfaceHigh: Color(0xFF383835),
    panelBorder: Color(0xFF383835),
    inputBackground: Color(0xFF212120),
    inputForeground: Color(0xFFC3C0B8),
    inputBorder: Color(0xFF383835),
    accent: Color(0xFFF4906F),
    onAccent: Color(0xFF262624),
    accentSecondary: Color(0xFF3A3A37),
    onAccentSecondary: Color(0xFFC3C0B8),
    selection: Color(0xFF3A3A37),
    borderSubtle: Color(0xFF383835),
    borderStrong: Color(0xFFF4906F),
    error: Color(0xFFD68585),
    warning: Color(0xFFB99D4A),
    success: Color(0xFF8FB78C),
  );

  /// Token Light Inspired.
  static const tokenLightInspired = MetroColorScheme(
    name: 'Token Light Inspired',
    brightness: Brightness.light,
    readerBackground: Color(0xFFFAF9F5),
    readerForeground: Color(0xFF323128),
    chromeBackground: Color(0xFFF6F5F1),
    chromeForeground: Color(0xFF323128),
    chromeBorder: Color(0xFFEAE9E5),
    surface: Color(0xFFF6F5F1),
    surfaceLow: Color(0xFFF0EFEB),
    surfaceHigh: Color(0xFFEAE9E5),
    panelBorder: Color(0xFFEAE9E5),
    inputBackground: Color(0xFFF6F5F1),
    inputForeground: Color(0xFF323128),
    inputBorder: Color(0xFFEAE9E5),
    accent: Color(0xFF863716),
    onAccent: Color(0xFFFAF9F5),
    accentSecondary: Color(0xFFDDDCD6),
    onAccentSecondary: Color(0xFF323128),
    selection: Color(0xFFDDDCD6),
    borderSubtle: Color(0xFFEAE9E5),
    borderStrong: Color(0xFF863716),
    error: Color(0xFFAD5253),
    warning: Color(0xFF857238),
    success: Color(0xFF365A33),
  );

  // ---------------------------------------------------------------------------
  // Convenient Aliases
  // ---------------------------------------------------------------------------

  /// Alias for [flexokiDarkInspired].
  static const flexokiDark = flexokiDarkInspired;

  /// Alias for [flexokiLightInspired].
  static const flexokiLight = flexokiLightInspired;

  /// Alias for [kanagawaDragonInspired].
  static const kanagawaDragon = kanagawaDragonInspired;

  /// Alias for [kanagawaWaveInspired].
  static const kanagawaWave = kanagawaWaveInspired;

  /// Alias for [kanagawaLotusInspired].
  static const kanagawaLotus = kanagawaLotusInspired;

  /// Alias for [tokenDarkInspired].
  static const tokenDark = tokenDarkInspired;

  /// Alias for [tokenLightInspired].
  static const tokenLight = tokenLightInspired;

  /// All 7 available built-in inspired Metro color schemes.
  static const List<MetroColorScheme> all = [
    flexokiDarkInspired,
    flexokiLightInspired,
    kanagawaDragonInspired,
    kanagawaLotusInspired,
    kanagawaWaveInspired,
    tokenDarkInspired,
    tokenLightInspired,
  ];

  /// Resolves a scheme by name (case-insensitive, with or without 'Inspired').
  static MetroColorScheme? findByName(String name) {
    final lower = name.toLowerCase().trim();
    final normalized = lower.replaceAll(' inspired', '').trim();
    for (final s in all) {
      final sName = s.name.toLowerCase().trim();
      final sNormalized = sName.replaceAll(' inspired', '').trim();
      if (sName == lower || sNormalized == normalized || sNormalized == lower) {
        return s;
      }
    }
    return null;
  }
}
