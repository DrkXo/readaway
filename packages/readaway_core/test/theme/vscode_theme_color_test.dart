import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('MetroColorScheme registry', () {
    test(
      'contains all 7 pre-compiled inspired themes and finds them by name',
      () {
        expect(MetroColorScheme.all.length, 7);
        expect(
          MetroColorScheme.kanagawaDragon.name,
          'Kanagawa Dragon Inspired',
        );
        expect(MetroColorScheme.kanagawaDragon.isDark, isTrue);
        expect(
          MetroColorScheme.kanagawaDragon.readerBackground,
          const Color(0xFF181616),
        );
        expect(
          MetroColorScheme.kanagawaDragon.readerForeground,
          const Color(0xFFC5C9C5),
        );

        expect(MetroColorScheme.flexokiDark.name, 'Flexoki Dark Inspired');
        expect(
          MetroColorScheme.flexokiDark.readerBackground,
          const Color(0xFF100F0F),
        );
        expect(
          MetroColorScheme.flexokiLight.readerBackground,
          const Color(0xFFFFFCF0),
        );

        expect(MetroColorScheme.tokenDark.name, 'Token Dark Inspired');
        expect(
          MetroColorScheme.tokenDark.readerBackground,
          const Color(0xFF262624),
        );

        // Finds by original or inspired name
        final foundOriginal = MetroColorScheme.findByName('Kanagawa Dragon');
        expect(foundOriginal, isNotNull);
        expect(foundOriginal?.name, 'Kanagawa Dragon Inspired');

        final foundInspired = MetroColorScheme.findByName(
          'Kanagawa Dragon Inspired',
        );
        expect(foundInspired, isNotNull);
        expect(foundInspired?.name, 'Kanagawa Dragon Inspired');

        final foundFlexoki = MetroColorScheme.findByName('Flexoki Dark');
        expect(foundFlexoki, isNotNull);
        expect(foundFlexoki?.name, 'Flexoki Dark Inspired');
      },
    );

    test('VsCodeThemeColorX resolves standard UI colors accurately', () {
      final theme = MetroColorScheme.kanagawaDragon.toVsCodeTheme();
      expect(theme.editorBackground, const Color(0xFF181616));
      expect(theme.editorForeground, const Color(0xFFC5C9C5));
      expect(theme.statusBarBackground, const Color(0xFF0D0C0C));
      expect(theme.titleBarBackground, const Color(0xFF393836));
      expect(theme.badgeBackground, const Color(0xFF658594));

      // Comprehensive Workbench token getters
      expect(theme.topbarBackground, isNotNull);
      expect(theme.topbarForeground, isNotNull);
      expect(theme.topbarBorder, isNotNull);
      expect(theme.sidebarBackground, isNotNull);
      expect(theme.sidebarForeground, isNotNull);
      expect(theme.sidebarBorder, isNotNull);
      expect(theme.sidebarSectionHeaderBackground, isNotNull);
      expect(theme.sidebarSectionHeaderForeground, isNotNull);
      expect(theme.bottombarBackground, isNotNull);
      expect(theme.bottombarForeground, isNotNull);
      expect(theme.bottombarBorder, isNotNull);
      expect(theme.readerBackground, isNotNull);
      expect(theme.readerForeground, isNotNull);
      expect(theme.panelBackground, isNotNull);
      expect(theme.panelBorder, isNotNull);
      expect(theme.editorWidgetBackground, isNotNull);
      expect(theme.editorWidgetBorder, isNotNull);
      expect(theme.inputBackground, isNotNull);
      expect(theme.inputForeground, isNotNull);
      expect(theme.inputBorder, isNotNull);
      expect(theme.buttonBackground, isNotNull);
      expect(theme.buttonForeground, isNotNull);
      expect(theme.listHoverBackground, isNotNull);
      expect(theme.listActiveSelectionBackground, isNotNull);
      expect(theme.notificationBackground, isNotNull);
      expect(theme.notificationForeground, isNotNull);
      expect(theme.borderSubtle, isNotNull);
      expect(theme.borderStrong, isNotNull);
      expect(theme.scrollbarBackground, isNotNull);
    });

    test('all 7 built-in themes resolve workbench tokens without error', () {
      for (final scheme in MetroColorScheme.all) {
        final theme = scheme.toVsCodeTheme();
        expect(theme.readerBackground, isNotNull);
        expect(theme.readerForeground, isNotNull);
        expect(theme.topbarBackground, isNotNull);
        expect(theme.topbarForeground, isNotNull);
        expect(theme.sidebarBackground, isNotNull);
        expect(theme.sidebarForeground, isNotNull);
        expect(theme.bottombarBackground, isNotNull);
        expect(theme.bottombarForeground, isNotNull);
        expect(theme.buttonBackground, isNotNull);
        expect(theme.buttonForeground, isNotNull);
        expect(theme.panelBackground, isNotNull);
        expect(theme.inputBackground, isNotNull);
        expect(theme.listActiveSelectionBackground, isNotNull);
        expect(theme.scheme, isNotNull);
      }
    });
  });

  group('MetroColorScheme', () {
    test('converts to VsCodeTheme with accurate color mappings', () {
      const metro = MetroColorScheme.kanagawaDragon;
      final vsTheme = metro.toVsCodeTheme();

      expect(vsTheme.name, 'Kanagawa Dragon Inspired');
      expect(vsTheme.type, 'dark');
      expect(vsTheme.editorBackground, const Color(0xFF181616));
      expect(vsTheme.editorForeground, const Color(0xFFC5C9C5));
      expect(vsTheme.buttonBackground, const Color(0xFF658594));
      expect(vsTheme.buttonForeground, const Color(0xFF181616));
      expect(vsTheme.error, const Color(0xFFE82424));
    });

    test('converts to Flutter ColorScheme accurately', () {
      const darkMetro = MetroColorScheme.tokenDark;
      final darkScheme = darkMetro.toColorScheme();
      expect(darkScheme.brightness, Brightness.dark);
      expect(darkScheme.primary, darkMetro.accent);
      expect(darkScheme.surface, darkMetro.surface);

      const lightMetro = MetroColorScheme.tokenLight;
      final lightScheme = lightMetro.toColorScheme();
      expect(lightScheme.brightness, Brightness.light);
      expect(lightScheme.primary, lightMetro.accent);
      expect(lightScheme.surface, lightMetro.surface);
    });
  });
}
