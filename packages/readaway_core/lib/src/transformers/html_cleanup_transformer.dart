import '../models/models.dart';
import 'text_transformer.dart';

/// Sanitizes web-clipped HTML artifacts, malformed CSS properties in inline styles,
/// and clipboard leftover styles that interfere with reader layout.
class HtmlCleanupTransformer implements TextTransformer {
  const HtmlCleanupTransformer();

  @override
  String get name => 'html_cleanup';

  @override
  String transform(TransformContext context) {
    var content = context.content;
    if (content.isEmpty) return content;

    // 1. Clean up malformed inline CSS and clipboard artifacts
    content = _sanitizeInlineStyles(content);

    // 2. Remove Apple-tab-span wrapper classes
    content = content.replaceAll(RegExp(r'\bApple-tab-span\b'), '');

    return content;
  }

  String _sanitizeInlineStyles(String html) {
    if (!html.contains('style=')) return html;

    final styleAttrRegex = RegExp(
      r'''style=(["'])(.*?)\1''',
      caseSensitive: false,
      dotAll: true,
    );

    return html.replaceAllMapped(styleAttrRegex, (match) {
      final quote = match.group(1)!;
      final rawStyle = match.group(2)!;

      final cleanedStyle = _cleanCssString(rawStyle);
      if (cleanedStyle.isEmpty) {
        return '';
      }
      return 'style=$quote$cleanedStyle$quote';
    });
  }

  String _cleanCssString(String rawCss) {
    final declarations = rawCss.split(';');
    final validDeclarations = <String>[];

    for (var decl in declarations) {
      decl = decl.trim();
      if (decl.isEmpty) continue;

      final colonIndex = decl.indexOf(':');
      if (colonIndex <= 0) continue; // Drop malformed tokens without colon (e.g. "text-decoration-")

      final prop = decl.substring(0, colonIndex).trim().toLowerCase();
      final value = decl.substring(colonIndex + 1).trim();

      // Drop broken properties with trailing hyphen or empty value
      if (prop.endsWith('-') || value.isEmpty) continue;

      // Drop browser clipboard noise
      if (prop == 'font-variant-ligatures' ||
          prop == 'font-variant-caps' ||
          prop == 'orphans' ||
          prop == 'widows') {
        continue;
      }

      validDeclarations.add('$prop: $value');
    }

    return validDeclarations.join('; ');
  }
}
