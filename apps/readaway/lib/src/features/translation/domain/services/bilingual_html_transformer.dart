import 'package:html/parser.dart' as html_parser;

/// Pre-render transformer that extracts translation units from chapter HTML
/// and injects bilingual or translated paragraphs for HyperRender.
class BilingualHtmlTransformer {
  const BilingualHtmlTransformer();

  /// Extracts readable text blocks from HTML that require translation.
  List<String> extractParagraphs(String rawHtml) {
    if (rawHtml.isEmpty) return [];
    try {
      final document = html_parser.parse(rawHtml);
      final blocks = document.querySelectorAll(
        'p, blockquote, h1, h2, h3, h4, h5, h6, li',
      );
      final texts = <String>[];
      for (final el in blocks) {
        final t = el.text.trim();
        if (t.isNotEmpty && t.length > 2) {
          texts.add(t);
        }
      }
      return texts;
    } catch (_) {
      return [];
    }
  }

  /// Transforms HTML to include bilingual translation beneath each paragraph.
  String injectBilingual({
    required String rawHtml,
    required Map<String, String> translations,
    double fontScale = 0.85,
  }) {
    if (rawHtml.isEmpty || translations.isEmpty) return rawHtml;
    try {
      final document = html_parser.parse(rawHtml);
      final blocks = document.querySelectorAll(
        'p, blockquote, h1, h2, h3, h4, h5, h6, li',
      );

      for (final el in blocks) {
        final t = el.text.trim();
        final translated = translations[t];
        if (translated != null && translated.isNotEmpty) {
          final transEl = document.createElement('div')
            ..className = 'readaway-bilingual-trans'
            ..attributes['style'] =
                'font-size: ${(fontScale * 100).toStringAsFixed(0)}%; '
                'opacity: 0.85; '
                'font-style: italic; '
                'margin-top: 4px; '
                'margin-bottom: 12px; '
                'line-height: 1.4;'
            ..text = translated;
          el.parent?.insertBefore(transEl, el.nextElementSibling);
        }
      }

      return document.body?.innerHtml ?? rawHtml;
    } catch (_) {
      return rawHtml;
    }
  }

  /// Replaces text in each paragraph with the target translation.
  String injectTranslatedOnly({
    required String rawHtml,
    required Map<String, String> translations,
  }) {
    if (rawHtml.isEmpty || translations.isEmpty) return rawHtml;
    try {
      final document = html_parser.parse(rawHtml);
      final blocks = document.querySelectorAll(
        'p, blockquote, h1, h2, h3, h4, h5, h6, li',
      );

      for (final el in blocks) {
        final t = el.text.trim();
        final translated = translations[t];
        if (translated != null && translated.isNotEmpty) {
          el.attributes['data-original'] = t;
          el.text = translated;
        }
      }

      return document.body?.innerHtml ?? rawHtml;
    } catch (_) {
      return rawHtml;
    }
  }
}
