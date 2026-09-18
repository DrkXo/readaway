import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('BuiltinVsCodeThemes registry', () {
    test('contains all 15 pre-compiled themes and finds them by name', () {
      expect(BuiltinVsCodeThemes.all.length, 15);
      expect(BuiltinVsCodeThemes.kanagawaDragon.name, 'Kanagawa Dragon');
      expect(BuiltinVsCodeThemes.kanagawaDragon.isDark, isTrue);
      expect(BuiltinVsCodeThemes.kanagawaDragon.editorBackground, const Color(0xFF181616));
      expect(BuiltinVsCodeThemes.kanagawaDragon.editorForeground, const Color(0xFFC5C9C5));

      expect(BuiltinVsCodeThemes.flexokiDark.name, 'Flexoki');
      expect(BuiltinVsCodeThemes.flexokiDark.editorBackground, const Color(0xFF100F0F));
      expect(BuiltinVsCodeThemes.flexokiLight.editorBackground, const Color(0xFFFFFCF0));

      expect(BuiltinVsCodeThemes.tokenDark.name, 'Token Dark');
      expect(BuiltinVsCodeThemes.tokenDark.editorBackground, const Color(0xFF262624));

      final found = BuiltinVsCodeThemes.findByName('Kanagawa Dragon');
      expect(found, isNotNull);
      expect(found?.name, 'Kanagawa Dragon');
    });

    test('VsCodeThemeColorX resolves standard UI colors accurately', () {
      final theme = BuiltinVsCodeThemes.kanagawaDragon;
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

    test('all 15 built-in themes resolve workbench tokens without error', () {
      for (final theme in BuiltinVsCodeThemes.all) {
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
}