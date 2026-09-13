import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme_scheme.dart';

void main() {
  group('ThemeSchemes', () {
    test('all contains the built-in tokenInspired scheme', () {
      expect(ThemeSchemes.all, contains(ThemeSchemes.tokenInspired));
      expect(ThemeSchemes.tokenInspired.id, 'tokenInspired');
      expect(ThemeSchemes.tokenInspired.name, 'Token (Inspired)');
    });

    test('byId resolves a known scheme', () {
      expect(ThemeSchemes.byId('tokenInspired'), ThemeSchemes.tokenInspired);
    });

    test('byId falls back to tokenInspired for unknown ids', () {
      expect(ThemeSchemes.byId('unknown'), ThemeSchemes.tokenInspired);
      expect(ThemeSchemes.byId(null), ThemeSchemes.tokenInspired);
    });
  });
}
