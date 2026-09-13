import 'theme.dart';

/// A named collection of light and dark [AppColors] palettes.
///
/// Schemes are the unit of theming: each one bundles a display name with the
/// color tokens used for light and dark mode. This is the extension point for
/// adding custom color schemes in the future.
class ThemeScheme {
  const ThemeScheme({
    required this.name,
    required this.light,
    required this.dark,
  });

  /// Human-readable name shown to users (e.g. in a scheme picker).
  final String name;

  /// Light-mode color tokens.
  final AppColors light;

  /// Dark-mode color tokens.
  final AppColors dark;
}

/// Registry of all available [ThemeScheme]s.
abstract final class ThemeSchemes {
  /// The built-in scheme, named "Token (Inspired)".
  static const tokenInspired = ThemeScheme(
    name: 'Token (Inspired)',
    light: AppColors.light,
    dark: AppColors.dark,
  );

  /// All available schemes, in display order.
  static const all = <ThemeScheme>[tokenInspired];
}
