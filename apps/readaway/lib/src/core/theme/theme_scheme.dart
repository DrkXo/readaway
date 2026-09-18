import 'package:readaway_core/readaway_core.dart';

/// A named collection of light and dark [VsCodeTheme] palettes.
///
/// Schemes are the unit of theming: each one bundles a stable [id] (used for
/// persistence), a display [name], and the VS Code themes used for light and
/// dark mode.
class ThemeScheme {
  const ThemeScheme({
    required this.id,
    required this.name,
    this.originalRepoLink,
    required this.light,
    required this.dark,
  });

  /// Stable identifier used to persist the selection (e.g. in settings).
  final String id;

  /// Human-readable name shown to users (e.g. in a scheme picker).
  final String name;

  /// Optional original repository / project URL.
  final String? originalRepoLink;

  /// Light-mode VS Code theme.
  final VsCodeTheme light;

  /// Dark-mode VS Code theme.
  final VsCodeTheme dark;
}

/// Registry of all available [ThemeScheme]s.
abstract final class ThemeSchemes {
  /// The built-in scheme, named "Token (Standard)".
  static final tokenInspired = ThemeScheme(
    id: 'tokenInspired',
    name: 'Token (Standard)',
    originalRepoLink: 'https://github.com/ThorstenRhau/token',
    light: BuiltinVsCodeThemes.tokenLight,
    dark: BuiltinVsCodeThemes.tokenDark,
  );

  /// Token Flint palette.
  static final tokenFlint = ThemeScheme(
    id: 'tokenFlint',
    name: 'Token Flint',
    originalRepoLink: 'https://github.com/ThorstenRhau/token',
    light: BuiltinVsCodeThemes.tokenFlintLight,
    dark: BuiltinVsCodeThemes.tokenFlintDark,
  );

  /// Token Meridian palette.
  static final tokenMeridian = ThemeScheme(
    id: 'tokenMeridian',
    name: 'Token Meridian',
    originalRepoLink: 'https://github.com/ThorstenRhau/token',
    light: BuiltinVsCodeThemes.tokenMeridianLight,
    dark: BuiltinVsCodeThemes.tokenMeridianDark,
  );

  /// Token Temper palette.
  static final tokenTemper = ThemeScheme(
    id: 'tokenTemper',
    name: 'Token Temper',
    originalRepoLink: 'https://github.com/ThorstenRhau/token',
    light: BuiltinVsCodeThemes.tokenTemperLight,
    dark: BuiltinVsCodeThemes.tokenTemperDark,
  );

  /// Token Ultra palette.
  static final tokenUltra = ThemeScheme(
    id: 'tokenUltra',
    name: 'Token Ultra',
    originalRepoLink: 'https://github.com/ThorstenRhau/token',
    light: BuiltinVsCodeThemes.tokenUltraLight,
    dark: BuiltinVsCodeThemes.tokenUltraDark,
  );

  /// Paper-and-ink scheme, named "Flexoki".
  static final flexoki = ThemeScheme(
    id: 'flexoki',
    name: 'Flexoki',
    originalRepoLink: 'https://github.com/kepano/flexoki',
    light: BuiltinVsCodeThemes.flexokiLight,
    dark: BuiltinVsCodeThemes.flexokiDark,
  );

  /// Kanagawa Dragon scheme.
  static final kanagawaDragon = ThemeScheme(
    id: 'kanagawaDragon',
    name: 'Kanagawa Dragon',
    originalRepoLink: 'https://github.com/paccodes/kanagawa-vscode-theme',
    light: BuiltinVsCodeThemes.kanagawaLotus,
    dark: BuiltinVsCodeThemes.kanagawaDragon,
  );

  /// Kanagawa Wave scheme.
  static final kanagawaWave = ThemeScheme(
    id: 'kanagawaWave',
    name: 'Kanagawa Wave',
    originalRepoLink: 'https://github.com/paccodes/kanagawa-vscode-theme',
    light: BuiltinVsCodeThemes.kanagawaLotus,
    dark: BuiltinVsCodeThemes.kanagawaWave,
  );

  /// Kanagawa Lotus scheme.
  static final kanagawaLotus = ThemeScheme(
    id: 'kanagawaLotus',
    name: 'Kanagawa Lotus',
    originalRepoLink: 'https://github.com/paccodes/kanagawa-vscode-theme',
    light: BuiltinVsCodeThemes.kanagawaLotus,
    dark: BuiltinVsCodeThemes.kanagawaWave,
  );

  /// All available schemes, in display order.
  static final all = <ThemeScheme>[
    flexoki,
    tokenInspired,
    tokenFlint,
    tokenMeridian,
    tokenTemper,
    tokenUltra,
    kanagawaDragon,
    kanagawaWave,
    kanagawaLotus,
  ];

  /// Resolves a scheme by [id], falling back to [flexoki] when the id
  /// is unknown or null (e.g. a scheme was removed from the registry).
  static ThemeScheme byId(String? id) => all.firstWhere(
    (scheme) => scheme.id == id,
    orElse: () => flexoki,
  );
}
