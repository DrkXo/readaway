import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../features/settings/domain/entity/settings.dart';
import '../theme/theme.dart';
import '../theme/theme_scheme.dart';
import 'settings_service.dart';

@Singleton()
class ThemeService {
  final SettingsService _settings;

  final _themeController = StreamController<ThemeMode>.broadcast();

  ThemeMode _currentThemeMode = ThemeMode.system;
  String? _currentSchemeId;
  StreamSubscription<Settings>? _settingsSub;

  ThemeMode get currentThemeMode => _currentThemeMode;
  Stream<ThemeMode> get themeChanges => _themeController.stream;

  /// All available color schemes, in display order.
  List<ThemeScheme> get schemes => ThemeSchemes.all;

  /// The currently active color scheme.
  ThemeScheme get currentScheme =>
      ThemeSchemes.byId(_settings.settings.globalViewSettings.selectedScheme);

  ThemeService({required this._settings});

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    _currentThemeMode = _modeFrom(_settings.settings);
    _currentSchemeId = _settings.settings.globalViewSettings.selectedScheme;
    _themeController.add(_currentThemeMode);
    _settingsSub = _settings.changes.listen(_onSettingsChanged);
  }

  ThemeMode _modeFrom(Settings settings) =>
      switch (settings.globalViewSettings.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  void _onSettingsChanged(Settings settings) {
    final mode = _modeFrom(settings);
    final schemeId = settings.globalViewSettings.selectedScheme;
    if (mode == _currentThemeMode && schemeId == _currentSchemeId) return;

    _currentThemeMode = mode;
    _currentSchemeId = schemeId;
    _themeController.add(mode);
  }

  ThemeData _buildThemeData(VsCodeTheme vsTheme) {
    final scheme = vsTheme.scheme;
    return ThemeData(
      colorScheme: scheme,
      extensions: [VsCodeThemeExtension(vsTheme)],
      useMaterial3: true,
      scaffoldBackgroundColor: vsTheme.readerBackground,
      canvasColor: vsTheme.readerBackground,
      cardColor: vsTheme.panelBackground,
      dividerColor: vsTheme.borderSubtle,
      dividerTheme: DividerThemeData(
        color: vsTheme.borderSubtle,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: vsTheme.topbarBackground,
        foregroundColor: vsTheme.topbarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(
            color: vsTheme.topbarBorder,
            width: 1.0,
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: vsTheme.sidebarBackground,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: vsTheme.sheetBackground,
        modalBackgroundColor: vsTheme.sheetBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          side: BorderSide(
            color: vsTheme.editorWidgetBorder,
            width: 1.0,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: vsTheme.editorWidgetBackground,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: vsTheme.editorWidgetBorder,
            width: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: vsTheme.inputBackground,
        hintStyle: TextStyle(
          color: vsTheme.inputPlaceholderForeground,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: vsTheme.inputBorder,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: vsTheme.inputBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: vsTheme.focusBorder,
            width: 1.5,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: vsTheme.badgeBackground ?? vsTheme.scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: vsTheme.borderSubtle,
        labelColor: vsTheme.readerForeground,
        unselectedLabelColor: vsTheme.readerForeground.withValues(alpha: 0.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: vsTheme.buttonBackground,
          foregroundColor: vsTheme.buttonForeground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: vsTheme.buttonSecondaryBackground,
        selectedColor: vsTheme.buttonBackground,
        labelStyle: TextStyle(color: vsTheme.buttonSecondaryForeground),
        secondaryLabelStyle: TextStyle(color: vsTheme.buttonForeground),
        checkmarkColor: vsTheme.buttonForeground,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return vsTheme.buttonForeground;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return vsTheme.buttonBackground;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return scheme.outline;
        }),
      ),
      listTileTheme: ListTileThemeData(
        selectedTileColor: vsTheme.listActiveSelectionBackground,
        selectedColor: vsTheme.listActiveSelectionForeground,
        textColor: vsTheme.readerForeground,
        iconColor: vsTheme.readerForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: vsTheme.badgeBackground ?? vsTheme.scheme.primary,
        inactiveTrackColor: vsTheme.borderSubtle,
        thumbColor: vsTheme.badgeBackground ?? vsTheme.scheme.primary,
        overlayColor: (vsTheme.badgeBackground ?? vsTheme.scheme.primary)
            .withValues(alpha: 0.15),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: vsTheme.dropdownBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: vsTheme.dropdownBorder,
            width: 1.0,
          ),
        ),
      ),
      textSelectionTheme: _selectionTheme(vsTheme),
    );
  }

  ThemeData getLightTheme() => _buildThemeData(currentScheme.light);

  ThemeData getDarkTheme() => _buildThemeData(currentScheme.dark);

  TextSelectionThemeData _selectionTheme(VsCodeTheme vsTheme) {
    final primary = vsTheme.badgeBackground ?? vsTheme.scheme.primary;
    return TextSelectionThemeData(
      cursorColor: primary,
      selectionColor:
          vsTheme.editorSelectionBackground ?? primary.withValues(alpha: 0.25),
      selectionHandleColor: primary,
    );
  }

  ThemeData getThemeData(BuildContext context) {
    switch (_currentThemeMode) {
      case ThemeMode.dark:
        return getDarkTheme();
      case ThemeMode.light:
        return getLightTheme();
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark
            ? getDarkTheme()
            : getLightTheme();
    }
  }

  @disposeMethod
  void dispose() {
    _settingsSub?.cancel();
    _themeController.close();
  }
}
