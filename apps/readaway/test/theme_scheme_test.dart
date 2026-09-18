import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme_scheme.dart';

void main() {
  group('ThemeSchemes', () {
    test('all contains tokenInspired, flexoki, and kanagawaDragon schemes', () {
      expect(ThemeSchemes.all, contains(ThemeSchemes.tokenInspired));
      expect(ThemeSchemes.all, contains(ThemeSchemes.flexoki));
      expect(ThemeSchemes.all, contains(ThemeSchemes.kanagawaDragon));
      expect(ThemeSchemes.tokenInspired.id, 'tokenInspired');
      expect(ThemeSchemes.tokenInspired.name, 'Token (Inspired)');
      expect(
        ThemeSchemes.tokenInspired.originalRepoLink,
        'https://github.com/ThorstenRhau/token',
      );
      expect(ThemeSchemes.flexoki.id, 'flexoki');
      expect(ThemeSchemes.flexoki.name, 'Flexoki (Inspired)');
      expect(
        ThemeSchemes.flexoki.originalRepoLink,
        'https://github.com/kepano/flexoki',
      );
      expect(ThemeSchemes.kanagawaDragon.id, 'kanagawaDragon');
      expect(ThemeSchemes.kanagawaDragon.name, 'Kanagawa Dragon (Inspired)');
      expect(
        ThemeSchemes.kanagawaDragon.originalRepoLink,
        'https://github.com/paccodes/kanagawa-vscode-theme',
      );
    });

    test('byId resolves a known scheme', () {
      expect(ThemeSchemes.byId('tokenInspired'), ThemeSchemes.tokenInspired);
      expect(ThemeSchemes.byId('flexoki'), ThemeSchemes.flexoki);
      expect(ThemeSchemes.byId('kanagawaDragon'), ThemeSchemes.kanagawaDragon);
    });

    test('byId falls back to tokenInspired for unknown ids', () {
      expect(ThemeSchemes.byId('unknown'), ThemeSchemes.tokenInspired);
      expect(ThemeSchemes.byId(null), ThemeSchemes.tokenInspired);
    });
  });
}
