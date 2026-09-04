import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../models/models.dart';
import '../theme/theme.dart';
import 'settings_service.dart';

@Singleton()
class ThemeService {
  final SettingsService _settings;

  final _themeController = StreamController<ThemeMode>.broadcast();

  ThemeMode _currentThemeMode = ThemeMode.system;

  ThemeMode get currentThemeMode => _currentThemeMode;
  Stream<ThemeMode> get themeChanges =>
      _themeController.stream.asBroadcastStream();

  ThemeService({required this._settings});

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    _currentThemeMode = _modeFrom(_settings.settings);
    _themeController.add(_currentThemeMode);
    _settings.changes.listen(_onSettingsChanged);
  }

  ThemeMode _modeFrom(Settings settings) =>
      switch (settings.globalViewSettings.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  void _onSettingsChanged(Settings settings) {
    final mode = _modeFrom(settings);
    if (mode == _currentThemeMode) return;

    _currentThemeMode = mode;
    _themeController.add(mode);
  }

  ThemeData getLightTheme() {
    final scheme = AppColors.light.scheme;
    return ThemeData(
      colorScheme: scheme,
      extensions: [AppColors.light],
      useMaterial3: true,
      textSelectionTheme: _selectionTheme(scheme),
    );
  }

  ThemeData getDarkTheme() {
    final scheme = AppColors.dark.scheme;
    return ThemeData(
      colorScheme: scheme,
      extensions: [AppColors.dark],
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
    _themeController.close();
  }
}
