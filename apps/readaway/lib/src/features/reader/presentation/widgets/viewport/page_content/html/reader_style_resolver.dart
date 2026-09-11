import 'package:flutter/material.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

/// Resolves and compiles [ReaderPreferences] into CSS stylesheets and base styles
/// for fluid HTML rendering in HyperRender.
class ReaderStyleResolver {
  const ReaderStyleResolver();

  /// Converts a [Color] to a hex string `#RRGGBB`.
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
  }

  /// Builds the dynamic CSS stylesheet to inject into HyperRender's [HtmlAdapter].
  String buildCustomCss({
    required ReaderPreferences prefs,
    required Color textColor,
    required Color backgroundColor,
    required Color linkColor,
    bool isDarkMode = false,
  }) {
    final textHex = colorToHex(textColor);
    final linkHex = colorToHex(linkColor);

    final resolvedFont = prefs.fontFamily ?? prefs.serifFont;
    final fontOverride = prefs.overrideFont ? ' !important' : '';
    final layoutOverride = prefs.overrideLayout ? ' !important' : '';

    final buffer = StringBuffer();

    // 1. Typography & Font styles
    buffer.writeln('''
      html, body {
        font-family: "$resolvedFont", serif$fontOverride;
        font-size: ${prefs.fontSize}px$fontOverride;
        color: $textHex;
        background-color: transparent;
      }
    ''');

    if (prefs.overrideFont) {
      buffer.writeln('''
        p, div, li, span, blockquote, dd, dt, h1, h2, h3, h4, h5, h6 {
          font-family: "$resolvedFont", serif !important;
        }
        pre, code, kbd, samp {
          font-family: "${prefs.monospaceFont}", monospace !important;
        }
      ''');
    }

    // 2. Paragraph & Layout styles
    final textAlign = prefs.fullJustification ? 'justify' : 'left';
    buffer.writeln('''
      p, li, dd, blockquote {
        line-height: ${prefs.lineHeight}$layoutOverride;
        word-spacing: ${prefs.wordSpacing}px$layoutOverride;
        letter-spacing: ${prefs.letterSpacing}px$layoutOverride;
        text-indent: ${prefs.textIndent}em$layoutOverride;
        text-align: $textAlign$layoutOverride;
        margin-top: ${prefs.paragraphMargin}em$layoutOverride;
        margin-bottom: ${prefs.paragraphMargin}em$layoutOverride;
      }

    ''');

    // 3. Headings & Structural formatting
    buffer.writeln('''
      h1, h2, h3, h4, h5, h6 {
        line-height: 1.25;
        margin-top: 1.2em;
        margin-bottom: 0.6em;
        text-align: ${prefs.fullJustification ? 'justify' : 'left'};
      }
      blockquote {
        margin-left: 1.5em;
        margin-right: 1.5em;
        opacity: 0.9;
      }
      table {
        max-width: 100%;
        border-collapse: collapse;
      }
      img, svg {
        max-width: 100%;
        height: auto;
      }
    ''');

    // 4. Colors & Links
    buffer.writeln('''
      a, a:any-link {
        color: $linkHex !important;
        text-decoration: underline;
      }
    ''');

    if (prefs.overrideColor) {
      buffer.writeln('''
        p, div, li, span, blockquote, dd, dt, h1, h2, h3, h4, h5, h6 {
          color: $textHex !important;
          background-color: transparent !important;
        }
      ''');
    }

    return buffer.toString();
  }

  /// Builds a Flutter [TextStyle] reflecting user typography settings.
  TextStyle buildBaseTextStyle({
    required ReaderPreferences prefs,
    required Color textColor,
  }) {
    FontWeight weight = FontWeight.normal;
    if (prefs.fontWeight == 'bold') {
      weight = FontWeight.bold;
    } else if (prefs.fontWeight == '300') {
      weight = FontWeight.w300;
    } else if (prefs.fontWeight == '500') {
      weight = FontWeight.w500;
    } else if (prefs.fontWeight == '600') {
      weight = FontWeight.w600;
    }

    return TextStyle(
      fontFamily: prefs.overrideFont ? (prefs.fontFamily ?? prefs.serifFont) : null,
      fontSize: prefs.fontSize,
      height: prefs.lineHeight,
      letterSpacing: prefs.letterSpacing != 0.0 ? prefs.letterSpacing : null,
      wordSpacing: prefs.wordSpacing != 0.0 ? prefs.wordSpacing : null,
      fontWeight: weight,
      color: textColor,
    );
  }
}
