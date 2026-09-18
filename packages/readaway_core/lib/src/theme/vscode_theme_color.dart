import 'package:flutter/material.dart';
import 'package:vscode_theme_parser/vscode_theme_parser.dart';

/// Parses a hex color string into a Flutter [Color].
///
/// Supports:
/// - `#RGB` -> `#RRGGBB`
/// - `#RGBA` -> `#AARRGGBB`
/// - `#RRGGBB` -> `0xFFRRGGBB`
/// - `#RRGGBBAA` -> `0xAARRGGBB`
Color? parseHexColor(String? hexString) {
  if (hexString == null) return null;
  var hex = hexString.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }

  if (hex.length == 3) {
    final r = hex[0];
    final g = hex[1];
    final b = hex[2];
    hex = '$r$r$g$g$b$b';
  } else if (hex.length == 4) {
    final r = hex[0];
    final g = hex[1];
    final b = hex[2];
    final a = hex[3];
    hex = '$a$a$r$r$g$g$b$b';
  }

  if (hex.length == 6) {
    final val = int.tryParse(hex, radix: 16);
    if (val != null) {
      return Color(0xFF000000 | val);
    }
  } else if (hex.length == 8) {
    // VS Code uses RRGGBBAA format
    final r = int.tryParse(hex.substring(0, 2), radix: 16);
    final g = int.tryParse(hex.substring(2, 4), radix: 16);
    final b = int.tryParse(hex.substring(4, 6), radix: 16);
    final a = int.tryParse(hex.substring(6, 8), radix: 16);
    if (r != null && g != null && b != null && a != null) {
      return Color.fromARGB(a, r, g, b);
    }
  }
  return null;
}

/// Convenience [Color] getters for [VsCodeTheme].
extension VsCodeThemeColorX on VsCodeTheme {
  /// Resolves a [Color] by its VS Code color key (e.g. `'editor.background'`, `'activityBar.background'`).
  Color? color(String key) => parseHexColor(colors[key]);

  /// Resolves a [Color] by its key, falling back to [fallback] if not found or invalid.
  Color colorOr(String key, Color fallback) => color(key) ?? fallback;

  // -------------------------------------------------------------------------
  // 1. Title Bar & Window Chrome
  // -------------------------------------------------------------------------

  /// Top bar / Title bar background color.
  Color? get titleBarBackground =>
      color('titleBar.activeBackground') ?? color('activityBar.background');

  /// Top bar / Title bar foreground color.
  Color? get titleBarForeground =>
      color('titleBar.activeForeground') ?? color('activityBar.foreground');

  /// Top navigation / chrome bar background (never null).
  Color get topbarBackground =>
      titleBarBackground ??
      (brightness == Brightness.dark
          ? const Color(0xFF181616)
          : const Color(0xFFFAFAFD));

  /// Top navigation / chrome bar text & icon color (never null).
  Color get topbarForeground => titleBarForeground ?? readerForeground;

  /// Top bar / Title bar border (never null).
  Color get topbarBorder =>
      color('titleBar.border') ??
      color('activityBar.border') ??
      borderSubtle;

  /// Inactive Title bar background.
  Color get topbarInactiveBackground =>
      color('titleBar.inactiveBackground') ?? topbarBackground;

  /// Inactive Title bar foreground.
  Color get topbarInactiveForeground =>
      color('titleBar.inactiveForeground') ??
      topbarForeground.withValues(alpha: 0.6);

  // -------------------------------------------------------------------------
  // 2. Side Bar, Activity Bar & Table of Contents
  // -------------------------------------------------------------------------

  /// Side bar / drawer background color (`sideBar.background`).
  Color? get sideBarBackground => color('sideBar.background');

  /// Side bar / drawer foreground color (`sideBar.foreground`).
  Color? get sideBarForeground => color('sideBar.foreground');

  /// Sidebar background (never null).
  Color get sidebarBackground =>
      sideBarBackground ??
      (brightness == Brightness.dark
          ? const Color(0xFF181616)
          : const Color(0xFFF2F0E5));

  /// Sidebar foreground (never null).
  Color get sidebarForeground => sideBarForeground ?? readerForeground;

  /// Sidebar border (never null).
  Color get sidebarBorder =>
      color('sideBar.border') ??
      color('activityBar.border') ??
      borderSubtle;

  /// Sidebar title foreground (never null).
  Color get sidebarTitleForeground =>
      color('sideBarTitle.foreground') ?? sidebarForeground;

  /// Sidebar section header background (never null).
  Color get sidebarSectionHeaderBackground =>
      color('sideBarSectionHeader.background') ??
      (brightness == Brightness.dark
          ? const Color(0xFF282726)
          : const Color(0xFFE6E4D9));

  /// Sidebar section header foreground (never null).
  Color get sidebarSectionHeaderForeground =>
      color('sideBarSectionHeader.foreground') ?? sidebarForeground;

  /// Sidebar section header border (never null).
  Color get sidebarSectionHeaderBorder =>
      color('sideBarSectionHeader.border') ?? borderSubtle;

  /// Sidebar active / selected item background (never null).
  Color get sidebarActiveBackground =>
      color('sideBar.activeBackground') ?? listActiveSelectionBackground;

  /// Sidebar active / selected item foreground (never null).
  Color get sidebarActiveForeground =>
      color('sideBar.activeForeground') ?? listActiveSelectionForeground;

  /// Sidebar item hover background (never null).
  Color get sidebarHoverBackground =>
      color('sideBar.hoverBackground') ?? listHoverBackground;

  /// Sidebar item hover foreground (never null).
  Color get sidebarHoverForeground =>
      color('sideBar.hoverForeground') ?? listHoverForeground;

  // -------------------------------------------------------------------------
  // 3. Status Bar & Bottom Controls
  // -------------------------------------------------------------------------

  /// Status bar / bottom bar background color (`statusBar.background`).
  Color? get statusBarBackground => color('statusBar.background');

  /// Status bar / bottom bar foreground color (`statusBar.foreground`).
  Color? get statusBarForeground => color('statusBar.foreground');

  /// Bottom toolbar / status bar background (never null).
  Color get bottombarBackground =>
      statusBarBackground ??
      (brightness == Brightness.dark
          ? const Color(0xFF100F0F)
          : const Color(0xFFF2F0E5));

  /// Bottom toolbar / status bar text & icon color (never null).
  Color get bottombarForeground => statusBarForeground ?? readerForeground;

  /// Bottom toolbar / status bar border (never null).
  Color get bottombarBorder =>
      color('statusBar.border') ?? borderSubtle;

  /// Status bar debugging background.
  Color get statusBarDebuggingBackground =>
      color('statusBar.debuggingBackground') ?? error;

  /// Status bar debugging foreground.
  Color get statusBarDebuggingForeground =>
      color('statusBar.debuggingForeground') ??
      (brightness == Brightness.dark ? const Color(0xFF100F0F) : Colors.white);

  /// Status bar item hover background.
  Color get statusBarItemHoverBackground =>
      color('statusBarItem.hoverBackground') ?? listHoverBackground;

  /// Status bar item active / pressed background.
  Color get statusBarItemActiveBackground =>
      color('statusBarItem.activeBackground') ?? listActiveSelectionBackground;

  // -------------------------------------------------------------------------
  // 4. Editor & Reader Viewport Canvas
  // -------------------------------------------------------------------------

  /// Document/Editor viewport background color (`editor.background`).
  Color? get editorBackground => color('editor.background');

  /// Document/Editor text color (`editor.foreground`).
  Color? get editorForeground => color('editor.foreground');

  /// Document/Reader viewport background canvas (never null).
  Color get readerBackground =>
      editorBackground ??
      (brightness == Brightness.dark
          ? const Color(0xFF181616)
          : const Color(0xFFFFFFFF));

  /// Document/Reader body text color (never null).
  Color get readerForeground =>
      editorForeground ??
      (brightness == Brightness.dark
          ? const Color(0xFFC5C9C5)
          : const Color(0xFF202020));

  /// Selection background (`editor.selectionBackground` or `editor.selectionHighlightBackground`).
  Color? get editorSelectionBackground =>
      color('editor.selectionBackground') ??
      color('editor.selectionHighlightBackground');

  /// Active line highlight background (`editor.lineHighlightBackground`).
  Color get editorLineHighlightBackground =>
      color('editor.lineHighlightBackground') ??
      (brightness == Brightness.dark
          ? const Color(0x1FFFFFFF)
          : const Color(0x0A000000));

  /// Active line highlight border (`editor.lineHighlightBorder`).
  Color get editorLineHighlightBorder =>
      color('editor.lineHighlightBorder') ?? borderSubtle;

  /// Hover highlight background (`editor.hoverHighlightBackground`).
  Color get editorHoverHighlightBackground =>
      color('editor.hoverHighlightBackground') ??
      listHoverBackground;

  /// Find match background (`editor.findMatchBackground`).
  Color get editorFindMatchBackground =>
      color('editor.findMatchBackground') ?? warning;

  /// Find match highlight background (`editor.findMatchHighlightBackground`).
  Color get editorFindMatchHighlightBackground =>
      color('editor.findMatchHighlightBackground') ??
      warning.withValues(alpha: 0.5);

  /// Find range highlight background (`editor.findRangeHighlightBackground`).
  Color get editorFindRangeHighlightBackground =>
      color('editor.findRangeHighlightBackground') ??
      editorLineHighlightBackground;

  /// Cursor / caret color (`editorCursor.foreground`).
  Color get editorCursorForeground =>
      color('editorCursor.foreground') ??
      badgeBackground ??
      readerForeground;

  /// Editor gutter background (`editorGutter.background`).
  Color get editorGutterBackground =>
      color('editorGutter.background') ?? readerBackground;

  /// Editor gutter added indicator (`editorGutter.addedBackground`).
  Color get editorGutterAdded =>
      color('editorGutter.addedBackground') ?? success;

  /// Editor gutter modified indicator (`editorGutter.modifiedBackground`).
  Color get editorGutterModified =>
      color('editorGutter.modifiedBackground') ?? warning;

  /// Editor gutter deleted indicator (`editorGutter.deletedBackground`).
  Color get editorGutterDeleted =>
      color('editorGutter.deletedBackground') ?? error;

  /// Editor inlay hint background (`editorInlayHint.background`).
  Color get editorInlayHintBackground =>
      color('editorInlayHint.background') ??
      (brightness == Brightness.dark
          ? const Color(0xFF282726)
          : const Color(0xFFE6E4D9));

  /// Editor inlay hint foreground (`editorInlayHint.foreground`).
  Color get editorInlayHintForeground =>
      color('editorInlayHint.foreground') ??
      readerForeground.withValues(alpha: 0.7);

  // -------------------------------------------------------------------------
  // 5. Panels, Sheets, Overlays & Quick Pick Widgets
  // -------------------------------------------------------------------------

  /// Panel background (`panel.background` or `editorWidget.background`).
  Color get panelBackground =>
      color('panel.background') ??
      color('editorWidget.background') ??
      sheetBackground;

  /// Panel border (`panel.border` or `editorWidget.border`).
  Color get panelBorder =>
      color('panel.border') ??
      color('editorWidget.border') ??
      borderSubtle;

  /// Panel title active border.
  Color get panelTitleActiveBorder =>
      color('panelTitle.activeBorder') ?? borderStrong;

  /// Panel title active foreground.
  Color get panelTitleActiveForeground =>
      color('panelTitle.activeForeground') ?? readerForeground;

  /// Popover, sheet, and menu background (never null).
  Color get sheetBackground =>
      sideBarBackground ??
      color('editorWidget.background') ??
      color('menu.background') ??
      readerBackground;

  /// Popover, sheet, and menu foreground (never null).
  Color get sheetForeground =>
      sideBarForeground ??
      color('editorWidget.foreground') ??
      color('menu.foreground') ??
      readerForeground;

  /// Editor widget background (`editorWidget.background`).
  Color get editorWidgetBackground =>
      color('editorWidget.background') ?? panelBackground;

  /// Editor widget border (`editorWidget.border`).
  Color get editorWidgetBorder =>
      color('editorWidget.border') ?? panelBorder;

  /// Editor widget foreground (`editorWidget.foreground`).
  Color get editorWidgetForeground =>
      color('editorWidget.foreground') ?? sheetForeground;

  /// Peek view border (`peekView.border`).
  Color get peekViewBorder =>
      color('peekView.border') ??
      badgeBackground ??
      borderStrong;

  /// Peek view title background (`peekViewTitle.background`).
  Color get peekViewTitleBackground =>
      color('peekViewTitle.background') ??
      panelBackground;

  /// Peek view editor background (`peekViewEditor.background`).
  Color get peekViewEditorBackground =>
      color('peekViewEditor.background') ??
      readerBackground;

  // -------------------------------------------------------------------------
  // 6. Inputs, Dropdowns & Menus
  // -------------------------------------------------------------------------

  /// Text input field background (`input.background`).
  Color get inputBackground =>
      color('input.background') ??
      color('editorWidget.background') ??
      (brightness == Brightness.dark
          ? const Color(0xFF100F0F)
          : const Color(0xFFF2F0E5));

  /// Text input field text color (`input.foreground`).
  Color get inputForeground =>
      color('input.foreground') ?? readerForeground;

  /// Text input field border (`input.border`).
  Color get inputBorder =>
      color('input.border') ?? borderSubtle;

  /// Text input field placeholder text color (`input.placeholderForeground`).
  Color get inputPlaceholderForeground =>
      color('input.placeholderForeground') ??
      readerForeground.withValues(alpha: 0.5);

  /// Active input option background (`inputOption.activeBackground`).
  Color get inputOptionActiveBackground =>
      color('inputOption.activeBackground') ??
      badgeBackground ??
      listActiveSelectionBackground;

  /// Active input option border (`inputOption.activeBorder`).
  Color get inputOptionActiveBorder =>
      color('inputOption.activeBorder') ?? borderStrong;

  /// Dropdown background (`dropdown.background`).
  Color get dropdownBackground =>
      color('dropdown.background') ?? inputBackground;

  /// Dropdown foreground (`dropdown.foreground`).
  Color get dropdownForeground =>
      color('dropdown.foreground') ?? inputForeground;

  /// Dropdown border (`dropdown.border`).
  Color get dropdownBorder =>
      color('dropdown.border') ?? inputBorder;

  /// Dropdown list popup background (`dropdown.listBackground`).
  Color get dropdownListBackground =>
      color('dropdown.listBackground') ?? editorWidgetBackground;

  /// Popup menu background (`menu.background`).
  Color get menuBackground =>
      color('menu.background') ?? editorWidgetBackground;

  /// Popup menu foreground (`menu.foreground`).
  Color get menuForeground =>
      color('menu.foreground') ?? readerForeground;

  /// Popup menu selection background (`menu.selectionBackground`).
  Color get menuSelectionBackground =>
      color('menu.selectionBackground') ?? listActiveSelectionBackground;

  /// Popup menu selection foreground (`menu.selectionForeground`).
  Color get menuSelectionForeground =>
      color('menu.selectionForeground') ?? listActiveSelectionForeground;

  /// Popup menu border (`menu.border`).
  Color get menuBorder =>
      color('menu.border') ?? borderSubtle;

  /// Popup menu separator (`menu.separatorBackground`).
  Color get menuSeparator =>
      color('menu.separatorBackground') ?? borderSubtle;

  // -------------------------------------------------------------------------
  // 7. Buttons, Badges & Accents
  // -------------------------------------------------------------------------

  /// Accent / badge background (`activityBarBadge.background` or `badge.background` or `button.background`).
  Color? get badgeBackground =>
      color('activityBarBadge.background') ??
      color('badge.background') ??
      color('button.background');

  /// Accent / badge foreground (`activityBarBadge.foreground` or `badge.foreground` or `button.foreground`).
  Color? get badgeForeground =>
      color('activityBarBadge.foreground') ??
      color('badge.foreground') ??
      color('button.foreground');

  /// Primary button background (`button.background`).
  Color get buttonBackground =>
      color('button.background') ??
      badgeBackground ??
      (brightness == Brightness.dark
          ? const Color(0xFF3AA99F)
          : const Color(0xFF24837B));

  /// Primary button text color (`button.foreground`).
  Color get buttonForeground =>
      color('button.foreground') ??
      (brightness == Brightness.dark
          ? const Color(0xFF100F0F)
          : const Color(0xFFFFFFFF));

  /// Secondary button background (`button.secondaryBackground`).
  Color get buttonSecondaryBackground =>
      color('button.secondaryBackground') ??
      color('activityBar.activeBackground') ??
      (brightness == Brightness.dark
          ? const Color(0xFF282726)
          : const Color(0xFFE6E4D9));

  /// Secondary button foreground (`button.secondaryForeground`).
  Color get buttonSecondaryForeground =>
      color('button.secondaryForeground') ?? readerForeground;

  // -------------------------------------------------------------------------
  // 8. Lists & Selection
  // -------------------------------------------------------------------------

  /// List item hover background (`list.hoverBackground`).
  Color get listHoverBackground =>
      color('list.hoverBackground') ??
      (brightness == Brightness.dark
          ? const Color(0x1FFFFFFF)
          : const Color(0x0A000000));

  /// List item hover foreground (`list.hoverForeground`).
  Color get listHoverForeground =>
      color('list.hoverForeground') ?? readerForeground;

  /// List item active selection background (`list.activeSelectionBackground`).
  Color get listActiveSelectionBackground =>
      color('list.activeSelectionBackground') ??
      (brightness == Brightness.dark
          ? const Color(0x33FFFFFF)
          : const Color(0x1F000000));

  /// List item active selection foreground (`list.activeSelectionForeground`).
  Color get listActiveSelectionForeground =>
      color('list.activeSelectionForeground') ?? readerForeground;

  /// List item inactive selection background (`list.inactiveSelectionBackground`).
  Color get listInactiveSelectionBackground =>
      color('list.inactiveSelectionBackground') ?? listHoverBackground;

  /// List item inactive selection foreground (`list.inactiveSelectionForeground`).
  Color get listInactiveSelectionForeground =>
      color('list.inactiveSelectionForeground') ?? readerForeground;

  /// Focus outline border (`focusBorder`).
  Color get focusBorder =>
      color('focusBorder') ?? borderStrong;

  // -------------------------------------------------------------------------
  // 9. Feedback & Notifications
  // -------------------------------------------------------------------------

  /// Notification / Toast background (`notifications.background`).
  Color get notificationBackground =>
      color('notifications.background') ?? editorWidgetBackground;

  /// Notification / Toast foreground (`notifications.foreground`).
  Color get notificationForeground =>
      color('notifications.foreground') ?? readerForeground;

  /// Notification / Toast border (`notifications.border`).
  Color get notificationBorder =>
      color('notifications.border') ?? editorWidgetBorder;

  /// Success state color (e.g. download complete, TTS active).
  Color get success =>
      color('terminal.ansiGreen') ??
      color('gitDecoration.addedResourceForeground') ??
      const Color(0xFF879A39);

  /// Text / icon color on [success] surface.
  Color get onSuccess =>
      brightness == Brightness.dark
          ? const Color(0xFF100F0F)
          : const Color(0xFFFFFFFF);

  /// Warning state color.
  Color get warning =>
      color('terminal.ansiYellow') ??
      color('editorWarning.foreground') ??
      const Color(0xFFD0A215);

  /// Text / icon color on [warning] surface.
  Color get onWarning =>
      brightness == Brightness.dark
          ? const Color(0xFF100F0F)
          : const Color(0xFFFFFFFF);

  /// Error state color.
  Color get error =>
      color('errorForeground') ??
      color('editorError.foreground') ??
      const Color(0xFFD14D41);

  /// Text / icon color on [error] surface.
  Color get onError => Colors.white;

  // -------------------------------------------------------------------------
  // 10. Borders, Shadows & Scrollbars
  // -------------------------------------------------------------------------

  /// Subtle separator / indent guide border (never null).
  Color get borderSubtle =>
      color('editorIndentGuide.background1') ??
      color('editorGroup.border') ??
      color('activityBar.border') ??
      (brightness == Brightness.dark
          ? const Color(0x33FFFFFF)
          : const Color(0x1F000000));

  /// Strong / active outline border (never null).
  Color get borderStrong =>
      color('editorIndentGuide.activeBackground1') ??
      color('contrastBorder') ??
      color('focusBorder') ??
      (brightness == Brightness.dark
          ? const Color(0x66FFFFFF)
          : const Color(0x3D000000));

  /// Scrollbar slider background (`scrollbarSlider.background`).
  Color get scrollbarBackground =>
      color('scrollbarSlider.background') ??
      (brightness == Brightness.dark
          ? const Color(0x33FFFFFF)
          : const Color(0x22000000));

  /// Scrollbar slider hover background (`scrollbarSlider.hoverBackground`).
  Color get scrollbarHoverBackground =>
      color('scrollbarSlider.hoverBackground') ??
      (brightness == Brightness.dark
          ? const Color(0x55FFFFFF)
          : const Color(0x44000000));

  /// Scrollbar slider active background (`scrollbarSlider.activeBackground`).
  Color get scrollbarActiveBackground =>
      color('scrollbarSlider.activeBackground') ??
      (brightness == Brightness.dark
          ? const Color(0x77FFFFFF)
          : const Color(0x66000000));

  /// Small elevation shadow.
  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: brightness == Brightness.dark ? 0.25 : 0.06,
          ),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Medium elevation shadow.
  List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: brightness == Brightness.dark ? 0.35 : 0.12,
          ),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Large elevation shadow.
  List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: brightness == Brightness.dark ? 0.45 : 0.18,
          ),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  /// Dynamically computes a Flutter [ColorScheme] from VS Code color keys.
  ColorScheme toColorScheme() {
    final isDark = brightness == Brightness.dark;
    final fg = readerForeground;
    final surface = panelBackground;
    final primary = buttonBackground;
    final primaryFg = buttonForeground;
    final secondary = buttonSecondaryBackground;
    final onSecondary = buttonSecondaryForeground;
    final err = error;
    final outline = borderSubtle;
    final outlineVariant = borderStrong;

    if (isDark) {
      return ColorScheme.dark(
        primary: primary,
        onPrimary: primaryFg,
        primaryContainer: buttonSecondaryBackground,
        onPrimaryContainer: fg,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: fg,
        surfaceContainerLowest: readerBackground,
        surfaceContainerLow: sidebarBackground,
        surfaceContainer: panelBackground,
        surfaceContainerHigh: editorWidgetBackground,
        surfaceContainerHighest: inputBackground,
        onSurfaceVariant: fg.withValues(alpha: 0.7),
        error: err,
        onError: Colors.white,
        outline: outline,
        outlineVariant: outlineVariant,
      );
    } else {
      return ColorScheme.light(
        primary: primary,
        onPrimary: primaryFg,
        primaryContainer: buttonSecondaryBackground,
        onPrimaryContainer: fg,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: fg,
        surfaceContainerLowest: readerBackground,
        surfaceContainerLow: sidebarBackground,
        surfaceContainer: panelBackground,
        surfaceContainerHigh: editorWidgetBackground,
        surfaceContainerHighest: inputBackground,
        onSurfaceVariant: fg.withValues(alpha: 0.7),
        error: err,
        onError: Colors.white,
        outline: outline,
        outlineVariant: outlineVariant,
      );
    }
  }

  /// Convenience getter for Flutter [ColorScheme].
  ColorScheme get scheme => toColorScheme();

  /// Flutter [Brightness] deduced from [type] or editor background luminance.
  Brightness get brightness {
    final t = type?.toLowerCase();
    if (t == 'light' || t == 'hclight') {
      return Brightness.light;
    }
    if (t == 'dark' || t == 'hcblack') {
      return Brightness.dark;
    }
    final bg = editorBackground;
    if (bg != null) {
      return bg.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;
    }
    return Brightness.dark;
  }
}

/// Convenience [Color] getters for [VsCodeTokenSettings].
extension VsCodeTokenSettingsColorX on VsCodeTokenSettings {
  Color? get foregroundColor => parseHexColor(foreground);
  Color? get backgroundColor => parseHexColor(background);
}

/// Convenience [Color] getters for [VsCodeSemanticTokenStyle].
extension VsCodeSemanticTokenStyleColorX on VsCodeSemanticTokenStyle {
  Color? get foregroundColor => parseHexColor(foreground);
}