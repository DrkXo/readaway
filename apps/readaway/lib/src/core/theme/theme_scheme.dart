import 'package:readaway_core/readaway_core.dart';

/// A named collection of light and dark [MetroColorScheme] palettes.
///
/// Schemes are the unit of theming: each one bundles a stable [id] (used for
/// persistence), a display [name], and the Metro color schemes used for light
/// and dark mode.
class ThemeScheme {
  const ThemeScheme({
    required this.id,
    required this.name,
    this.originalRepoLink,
    required this.metroLight,
    required this.metroDark,
  });

  /// Stable identifier used to persist the selection (e.g. in settings).
  final String id;

  /// Human-readable name shown to users (e.g. in a scheme picker).
  final String name;

  /// Optional original repository / project URL.
  final String? originalRepoLink;

  /// Light-mode Metro color scheme.
  final MetroColorScheme metroLight;

  /// Dark-mode Metro color scheme.
  final MetroColorScheme metroDark;

  /// Light-mode [VsCodeTheme] for compatibility with [VsCodeThemeColorX].
  VsCodeTheme get light => metroLight.toVsCodeTheme();

  /// Dark-mode [VsCodeTheme] for compatibility with [VsCodeThemeColorX].
  VsCodeTheme get dark => metroDark.toVsCodeTheme();
}

/// Registry of all available [ThemeScheme]s.
abstract final class ThemeSchemes {
  /// The built-in scheme, named "Token".
  static final token = ThemeScheme(
    id: 'token',
    name: 'Token',
    originalRepoLink: 'https://github.com/ThorstenRhau/token',
    metroLight: MetroColorScheme.tokenLight,
    metroDark: MetroColorScheme.tokenDark,
  );

  /// Paper-and-ink scheme, named "Flexoki".
  static final flexoki = ThemeScheme(
    id: 'flexoki',
    name: 'Flexoki',
    originalRepoLink: 'https://github.com/kepano/flexoki',
    metroLight: MetroColorScheme.flexokiLight,
    metroDark: MetroColorScheme.flexokiDark,
  );

  /// Kanagawa Dragon scheme.
  static final kanagawaDragon = ThemeScheme(
    id: 'kanagawaDragon',
    name: 'Kanagawa Dragon',
    originalRepoLink: 'https://github.com/paccodes/kanagawa-vscode-theme',
    metroLight: MetroColorScheme.kanagawaLotus,
    metroDark: MetroColorScheme.kanagawaDragon,
  );

  /// Kanagawa Wave scheme.
  static final kanagawaWave = ThemeScheme(
    id: 'kanagawaWave',
    name: 'Kanagawa Wave',
    originalRepoLink: 'https://github.com/paccodes/kanagawa-vscode-theme',
    metroLight: MetroColorScheme.kanagawaLotus,
    metroDark: MetroColorScheme.kanagawaWave,
  );

  /// Kanagawa Lotus scheme.
  static final kanagawaLotus = ThemeScheme(
    id: 'kanagawaLotus',
    name: 'Kanagawa Lotus',
    originalRepoLink: 'https://github.com/paccodes/kanagawa-vscode-theme',
    metroLight: MetroColorScheme.kanagawaLotus,
    metroDark: MetroColorScheme.kanagawaWave,
  );

  /// All available schemes, in display order.
  static final all = <ThemeScheme>[
    token,
    flexoki,
    kanagawaDragon,
    kanagawaWave,
    kanagawaLotus,
  ];

  /// Resolves a scheme by [id], falling back to [token] when the id
  /// is unknown or null (e.g. a scheme was removed from the registry).
  static ThemeScheme byId(String? id) {
    if (id == null) return token;
    final normalized = id.replaceAll('Inspired', '');
    return all.firstWhere(
      (scheme) => scheme.id == id || scheme.id == normalized,
      orElse: () => token,
    );
  }
}
