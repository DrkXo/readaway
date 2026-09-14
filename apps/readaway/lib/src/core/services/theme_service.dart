import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../models/models.dart';
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

  ThemeData getLightTheme() {
    final scheme = currentScheme.light.scheme;
    return ThemeData(
      colorScheme: scheme,
      extensions: [currentScheme.light],
      useMaterial3: true,
      textSelectionTheme: _selectionTheme(scheme),
    );
  }

  ThemeData getDarkTheme() {
    final scheme = currentScheme.dark.scheme;
    return ThemeData(
      colorScheme: scheme,
      extensions: [currentScheme.dark],
      useMaterial3: true,
      textSelectionTheme: _selectionTheme(scheme),
    );
  }

  TextSelectionThemeData _selectionTheme(ColorScheme scheme) {
    return TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.25),
      selectionHandleColor: scheme.primary,
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
