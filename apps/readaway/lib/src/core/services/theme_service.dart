part of 'services.dart';

@Singleton()
class ThemeService {
  static const String _themeKey = 'theme_mode';
  static const ThemeMode _defaultThemeMode = ThemeMode.system;

  final AppStorageService _storage;

  final _themeController = StreamController<ThemeMode>.broadcast();

  ThemeMode _currentThemeMode = _defaultThemeMode;

  ThemeMode get currentThemeMode => _currentThemeMode;
  Stream<ThemeMode> get themeChanges =>
      _themeController.stream.asBroadcastStream();

  ThemeService({
    required this._storage,
  });

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final savedMode = await _loadSavedThemeMode();
    _currentThemeMode = savedMode;
    _themeController.add(_currentThemeMode);
  }

  Future<ThemeMode> _loadSavedThemeMode() async {
    final saved = _storage.readAsString(_themeKey);
    if (saved == null) return _defaultThemeMode;

    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return _defaultThemeMode;
    }
  }

  Future<void> setLightMode() async => _setThemeMode(ThemeMode.light);

  Future<void> setDarkMode() async => _setThemeMode(ThemeMode.dark);

  Future<void> setSystemMode() async => _setThemeMode(ThemeMode.system);

  Future<void> toggleTheme() async {
    final newMode = _currentThemeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await _setThemeMode(newMode);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (mode != ThemeMode.system) {
      final key = mode == ThemeMode.dark ? 'dark' : 'light';
      await _storage.writeAsString(_themeKey, key);
    } else {
      await _storage.delete(_themeKey);
    }

    _currentThemeMode = mode;
    _themeController.add(_currentThemeMode);
  }

  ThemeData getLightTheme() {
    return ThemeData(
      colorScheme: AppColors.light.scheme,
      extensions: [AppColors.light],
      useMaterial3: true,
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      colorScheme: AppColors.dark.scheme,
      extensions: [AppColors.dark],
      useMaterial3: true,
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
