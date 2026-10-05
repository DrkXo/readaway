import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/tts_highlight_palette.dart';

void main() {
  const scheme = ColorScheme.light();

  group('resolveTtsHighlightColor', () {
    test('resolves preset keys to their swatch color', () {
      expect(
        resolveTtsHighlightColor('amber', scheme),
        const Color(0xFFF59E0B),
      );
      expect(
        resolveTtsHighlightColor('rose', scheme),
        const Color(0xFFF43F5E),
      );
    });

    test('"primary" follows the theme color scheme', () {
      expect(resolveTtsHighlightColor('primary', scheme), scheme.primary);
    });

    test('resolves custom hex values, including shorthand', () {
      expect(
        resolveTtsHighlightColor('#123456', scheme),
        const Color(0xFF123456),
      );
      expect(
        resolveTtsHighlightColor('#abc', scheme),
        const Color(0xFFAABBCC),
      );
    });

    test('falls back to the theme primary for unknown or malformed values', () {
      expect(resolveTtsHighlightColor('nope', scheme), scheme.primary);
      expect(resolveTtsHighlightColor('#zzz', scheme), scheme.primary);
      expect(resolveTtsHighlightColor(null, scheme), scheme.primary);
      expect(resolveTtsHighlightColor('', scheme), scheme.primary);
    });
  });

  group('custom hex helpers', () {
    test('isCustomTtsHighlightColor is true only for valid non-preset hex', () {
      expect(isCustomTtsHighlightColor('#123456'), isTrue);
      expect(isCustomTtsHighlightColor('amber'), isFalse);
      expect(isCustomTtsHighlightColor('#zzz'), isFalse);
      expect(isCustomTtsHighlightColor(null), isFalse);
    });

    test('normalizeHexColor normalises case, prefix, and shorthand', () {
      expect(normalizeHexColor('#abc'), '#AABBCC');
      expect(normalizeHexColor('0ea5e9'), '#0EA5E9');
      expect(normalizeHexColor('#AARRGG'), isNull);
      expect(normalizeHexColor('nope'), isNull);
    });

    test('colorToHex drops the alpha channel', () {
      expect(colorToHex(const Color(0x80123456)), '#123456');
    });
  });

  test('preset keys are unique', () {
    final keys = kTtsHighlightColorOptions.map((o) => o.key).toSet();
    expect(keys.length, kTtsHighlightColorOptions.length);
  });
}
