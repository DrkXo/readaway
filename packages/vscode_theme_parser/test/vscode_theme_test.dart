import 'dart:io';

import 'package:test/test.dart';
import 'package:vscode_theme_parser/vscode_theme_parser.dart';

const _themesDir = 'test/fixtures/vscode_themes';

void main() {
  group('JSONC parsing in VsCodeTheme.parse', () {
    test('removes single-line and multi-line comments while preserving URLs and strings', () {
      const jsonc = '''
      {
        // Schema definition
        "\$schema": "vscode://schemas/color-theme",
        /* Multi-line
           comment block */
        "name": "My Theme // with slash in string",
        "colors": {
          "editor.background": "#1E1E1E", // background color
          "editor.foreground": "#D4D4D4",
        },
      }
      ''';

      final theme = VsCodeTheme.parse(jsonc);
      expect(theme.name, 'My Theme // with slash in string');
      expect(theme.schema, 'vscode://schemas/color-theme');
      expect(theme.colors['editor.background'], '#1E1E1E');
      expect(theme.colors['editor.foreground'], '#D4D4D4');
    });

    test('strips trailing commas in nested structures', () {
      const jsonc = '''
      {
        "tokenColors": [
          {
            "name": "Comment",
            "scope": ["comment", "punctuation.definition.comment",],
            "settings": {
              "foreground": "#6A9955",
              "fontStyle": "italic",
            },
          },
        ],
      }
      ''';

      final theme = VsCodeTheme.parse(jsonc);
      expect(theme.tokenColors.length, 1);
      final rule = theme.tokenColors.first;
      expect(rule.name, 'Comment');
      expect(rule.scope?.selectors, [
        'comment',
        'punctuation.definition.comment',
      ]);
      expect(rule.settings.foreground, '#6A9955');
      expect(rule.settings.isItalic, isTrue);
    });
  });

  group('VsCodeTokenScope', () {
    test('parses single string scope', () {
      final scope = VsCodeTokenScope.fromSelectors(['comment.line']);
      expect(scope.selectors, ['comment.line']);
      expect(scope.matches('comment.line'), isTrue);
      expect(scope.matches('comment.line.double-slash'), isTrue);
      expect(scope.matches('string.quoted'), isFalse);
    });

    test('parses comma-separated string scope', () {
      final scope = VsCodeTokenScope.fromSelectors([
        'storage.type, keyword.operator, meta.function',
      ]);
      expect(scope.selectors, [
        'storage.type',
        'keyword.operator',
        'meta.function',
      ]);
      expect(scope.matches('keyword.operator'), isTrue);
      expect(scope.matches('keyword.operator.logical'), isTrue);
      expect(scope.matches('comment'), isFalse);
    });

    test('parses list of mixed selectors', () {
      final scope = VsCodeTokenScope.fromSelectors([
        'entity.name.function, support.function',
        'entity.name.method',
      ]);
      expect(scope.selectors, [
        'entity.name.function',
        'support.function',
        'entity.name.method',
      ]);
    });
  });

  group('VsCodeTokenSettings', () {
    test('parses font styles correctly', () {
      const s1 = VsCodeTokenSettings(fontStyle: 'italic bold');
      expect(s1.isItalic, isTrue);
      expect(s1.isBold, isTrue);
      expect(s1.isUnderline, isFalse);
      expect(s1.isStrikethrough, isFalse);
      expect(s1.isNone, isFalse);

      const s2 = VsCodeTokenSettings(fontStyle: 'underline strikethrough');
      expect(s2.isUnderline, isTrue);
      expect(s2.isStrikethrough, isTrue);
      expect(s2.isItalic, isFalse);
      expect(s2.isBold, isFalse);

      const s3 = VsCodeTokenSettings(fontStyle: '');
      expect(s3.isNone, isTrue);
    });

    test('handles fontSize and lineHeight as double or num', () {
      final json = {'foreground': '#FFF', 'fontSize': 14, 'lineHeight': 1.5};
      final settings = VsCodeTokenSettings.fromJson(json);
      expect(settings.fontSize, 14.0);
      expect(settings.lineHeight, 1.5);
    });
  });

  group('VsCodeSemanticTokenStyle', () {
    test('parses hex color shorthand and object formats', () {
      final json = {
        'newOperator': '#DCDCAA',
        'stringLiteral': {
          'foreground': '#CE9178',
          'bold': true,
          'italic': false,
        },
      };

      const converter = VsCodeSemanticTokensConverter();
      final styles = converter.fromJson(json);

      expect(styles['newOperator']?.foreground, '#DCDCAA');
      expect(styles['newOperator']?.isBold, isFalse);

      expect(styles['stringLiteral']?.foreground, '#CE9178');
      expect(styles['stringLiteral']?.isBold, isTrue);
      expect(styles['stringLiteral']?.isItalic, isFalse);
    });
  });

  group('Default VS Code themes parsing', () {
    final themesDir = _themesDir;

    final expectedThemes = <String, Map<String, dynamic>>{
      // Flexoki themes
      'Flexoki-Dark-color-theme.json': {
        'name': 'Flexoki',
        'type': 'dark',
        'tokenCount': 48,
        'hasColors': true,
      },
      'Flexoki-Light-color-theme.json': {
        'name': 'Flexoki',
        'type': 'light',
        'tokenCount': 48,
        'hasColors': true,
      },
      // Kanagawa themes
      'kanagawa-dragon-color-theme.json': {
        'name': 'Kanagawa Dragon',
        'type': 'dark',
        'tokenCount': 76,
        'hasColors': true,
      },
      'kanagawa-lotus-color-theme.json': {
        'name': 'Kanagawa Lotus',
        'type': 'light',
        'tokenCount': 76,
        'hasColors': true,
      },
      'kanagawa-wave-color-theme.json': {
        'name': 'Kanagawa Wave',
        'type': 'dark',
        'tokenCount': 76,
        'hasColors': true,
      },
      // Token themes
      'token-dark-color-theme.json': {
        'name': 'Token Dark',
        'type': 'dark',
        'tokenCount': 51,
        'hasColors': true,
      },
      'token-light-color-theme.json': {
        'name': 'Token Light',
        'type': 'light',
        'tokenCount': 51,
        'hasColors': true,
      },
      'token-flint-dark-color-theme.json': {
        'name': 'Token Flint Dark',
        'type': 'dark',
        'tokenCount': 48,
        'hasColors': true,
      },
      'token-flint-light-color-theme.json': {
        'name': 'Token Flint Light',
        'type': 'light',
        'tokenCount': 48,
        'hasColors': true,
      },
      'token-meridian-dark-color-theme.json': {
        'name': 'Token Meridian Dark',
        'type': 'dark',
        'tokenCount': 49,
        'hasColors': true,
      },
      'token-meridian-light-color-theme.json': {
        'name': 'Token Meridian Light',
        'type': 'light',
        'tokenCount': 49,
        'hasColors': true,
      },
      'token-temper-dark-color-theme.json': {
        'name': 'Token Temper Dark',
        'type': 'dark',
        'tokenCount': 48,
        'hasColors': true,
      },
      'token-temper-light-color-theme.json': {
        'name': 'Token Temper Light',
        'type': 'light',
        'tokenCount': 48,
        'hasColors': true,
      },
      'token-ultra-dark-color-theme.json': {
        'name': 'Token Ultra Dark',
        'type': 'dark',
        'tokenCount': 48,
        'hasColors': true,
      },
      'token-ultra-light-color-theme.json': {
        'name': 'Token Ultra Light',
        'type': 'light',
        'tokenCount': 48,
        'hasColors': true,
      },
    };

    for (final entry in expectedThemes.entries) {
      test('successfully parses ${entry.key}', () {
        final filePath = '$themesDir/${entry.key}';
        final file = File(filePath);
        expect(file.existsSync(), isTrue, reason: '$filePath must exist');

        final rawJsonc = file.readAsStringSync();
        final theme = VsCodeTheme.parse(rawJsonc);

        expect(theme.name, entry.value['name']);

        if (entry.value['type'] != null) {
          expect(theme.type, entry.value['type']);
        }

        if (entry.value['tokenCount'] != null) {
          expect(theme.tokenColors.length, entry.value['tokenCount']);
        }

        if (entry.value['semanticCount'] != null) {
          expect(
            theme.semanticTokenColors.length,
            entry.value['semanticCount'],
          );
        }

        if (entry.value['hasColors'] == true) {
          expect(theme.colors.isNotEmpty, isTrue);
        }

        if (entry.value['hasInclude'] == true) {
          expect(theme.include, isNotNull);
        }

        // Test serialization round-trip
        final jsonMap = theme.toJson();
        final reconstructed = VsCodeTheme.fromJson(jsonMap);
        expect(reconstructed.name, theme.name);
        expect(reconstructed.tokenColors.length, theme.tokenColors.length);
        expect(reconstructed.colors.length, theme.colors.length);
        expect(
          reconstructed.semanticTokenColors.length,
          theme.semanticTokenColors.length,
        );
      });
    }
  });

  group('Theme inheritance resolution (mergedWith)', () {
    test('correctly merges hierarchical themes', () {
      final baseTheme = VsCodeTheme(
        name: 'Base Theme',
        type: 'dark',
        colors: {
          'activityBar.background': '#111111',
          'tab.selectedBackground': '#37373D',
        },
        tokenColors: [
          VsCodeTokenColor(
            name: 'Base Comment',
            scope: VsCodeTokenScope.fromSelectors(['comment']),
            settings: const VsCodeTokenSettings(foreground: '#666666'),
          ),
        ],
      );

      final childTheme = VsCodeTheme(
        name: 'Child Theme',
        type: 'dark',
        colors: {'activityBar.background': '#222222'},
        tokenColors: [
          VsCodeTokenColor(
            name: 'Child Keyword',
            scope: VsCodeTokenScope.fromSelectors(['keyword']),
            settings: const VsCodeTokenSettings(foreground: '#FF0000'),
          ),
        ],
      );

      // Child inherits/overrides base
      final resolved = childTheme.mergedWith(baseTheme);

      expect(resolved.name, 'Child Theme');
      expect(resolved.type, 'dark');
      expect(resolved.isDark, isTrue);
      expect(resolved.colors.isNotEmpty, isTrue);
      // Colors from childTheme override base
      expect(resolved.colors['activityBar.background'], '#222222');
      // Fallback colors from base are preserved
      expect(resolved.colors['tab.selectedBackground'], '#37373D');
      // Token colors are merged
      expect(resolved.tokenColors.length, 2);
    });
  });
}
