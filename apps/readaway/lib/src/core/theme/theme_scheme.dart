import 'schemes/flexoki.dart';
import 'schemes/token_inspired.dart';
import 'theme.dart';

/// A named collection of light and dark [AppColors] palettes.
///
/// Schemes are the unit of theming: each one bundles a stable [id] (used for
/// persistence), a display [name], and the color tokens used for light and
/// dark mode. This is the extension point for adding custom color schemes in
/// the future.
class ThemeScheme {
  const ThemeScheme({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  /// Stable identifier used to persist the selection (e.g. in settings).
  final String id;

  /// Human-readable name shown to users (e.g. in a scheme picker).
  final String name;

  /// Light-mode color tokens.
  final AppColors light;

  /// Dark-mode color tokens.
  final AppColors dark;
}

/// Registry of all available [ThemeScheme]s.
abstract final class ThemeSchemes {
  /// The built-in scheme, named "Token".
  static const tokenInspired = ThemeScheme(
    id: 'tokenInspired',
    name: 'Token',
    light: tokenInspiredLight,
    dark: tokenInspiredDark,
  );

  /// Paper-and-ink scheme, named "Flexoki".
  static const flexoki = ThemeScheme(
    id: 'flexoki',
    name: 'Flexoki',
    light: flexokiLight,
    dark: flexokiDark,
  );

  /// All available schemes, in display order.
  static const all = <ThemeScheme>[tokenInspired, flexoki];

  /// Resolves a scheme by [id], falling back to [tokenInspired] when the id
  /// is unknown or null (e.g. a scheme was removed from the registry).
  static ThemeScheme byId(String? id) => all.firstWhere(
    (scheme) => scheme.id == id,
    orElse: () => tokenInspired,
  );
}
