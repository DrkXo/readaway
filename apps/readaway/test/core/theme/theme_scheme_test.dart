import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/theme/theme_scheme.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('ThemeSchemes', () {
    test('all contains all Kanagawa, Flexoki, and Token variations', () {
      expect(ThemeSchemes.all.length, 9);
      expect(ThemeSchemes.all, contains(ThemeSchemes.tokenInspired));
      expect(ThemeSchemes.all, contains(ThemeSchemes.tokenFlint));
      expect(ThemeSchemes.all, contains(ThemeSchemes.tokenMeridian));
      expect(ThemeSchemes.all, contains(ThemeSchemes.tokenTemper));
      expect(ThemeSchemes.all, contains(ThemeSchemes.tokenUltra));
      expect(ThemeSchemes.all, contains(ThemeSchemes.flexoki));
      expect(ThemeSchemes.all, contains(ThemeSchemes.kanagawaDragon));
      expect(ThemeSchemes.all, contains(ThemeSchemes.kanagawaWave));
      expect(ThemeSchemes.all, contains(ThemeSchemes.kanagawaLotus));
    });

    test('byId resolves known schemes', () {
      expect(ThemeSchemes.byId('tokenInspired'), ThemeSchemes.tokenInspired);
      expect(ThemeSchemes.byId('tokenFlint'), ThemeSchemes.tokenFlint);
      expect(ThemeSchemes.byId('flexoki'), ThemeSchemes.flexoki);
      expect(ThemeSchemes.byId('kanagawaDragon'), ThemeSchemes.kanagawaDragon);
      expect(ThemeSchemes.byId('kanagawaWave'), ThemeSchemes.kanagawaWave);
    });

    test('byId falls back to flexoki for unknown ids', () {
      expect(ThemeSchemes.byId('unknown'), ThemeSchemes.flexoki);
      expect(ThemeSchemes.byId(null), ThemeSchemes.flexoki);
    });
  });

  group('VsCodeTheme direct color resolution', () {
    test('resolves UI colors from theme properties accurately', () {
      const vsCodeJson = '''
      {
        "name": "Custom Theme",
        "type": "dark",
        "colors": {
          "editor.background": "#181616",
          "editor.foreground": "#C5C9C5",
          "titleBar.activeBackground": "#393836",
          "titleBar.activeForeground": "#C5C9C5",
          "statusBar.background": "#0D0C0C",
          "statusBar.foreground": "#C8C093",
          "activityBarBadge.background": "#658594",
          "activityBarBadge.foreground": "#FFFFFF"
        }
      }
      ''';

      final vsTheme = VsCodeTheme.parse(vsCodeJson);

      expect(vsTheme.editorBackground, const Color(0xFF181616));
      expect(vsTheme.editorForeground, const Color(0xFFC5C9C5));
      expect(vsTheme.titleBarBackground, const Color(0xFF393836));
      expect(vsTheme.statusBarBackground, const Color(0xFF0D0C0C));
      expect(vsTheme.statusBarForeground, const Color(0xFFC8C093));
      expect(vsTheme.badgeBackground, const Color(0xFF658594));
      expect(vsTheme.brightness, Brightness.dark);
    });

    test('parses various hex color formats', () {
      expect(parseHexColor('#RGB'), isNull); // 3 non-hex characters
      expect(parseHexColor('#fff'), const Color(0xFFFFFFFF));
      expect(parseHexColor('#181616'), const Color(0xFF181616));
      expect(parseHexColor('#18161680'), const Color(0x80181616));
      expect(parseHexColor(null), isNull);
    });
  });

  group('ThemeData VS Code workbench integration', () {
    test('VsCodeThemeExtension can be retrieved from ThemeData', () {
      final vsTheme = BuiltinVsCodeThemes.kanagawaDragon;
      final themeData = ThemeData(
        extensions: [VsCodeThemeExtension(vsTheme)],
      );

      final ext = themeData.extension<VsCodeThemeExtension>();
      expect(ext, isNotNull);
      expect(ext?.theme.name, 'Kanagawa Dragon');
      expect(ext?.theme.editorBackground, const Color(0xFF181616));
    });
  });
}
