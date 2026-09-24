import '../abstracts/reflowable_document_reader.dart';
import '../models/models.dart';

/// High-performance HTML text and footnote extractor implemented in pure Dart.
class HtmlTextExtractor {
  const HtmlTextExtractor._();

  static final RegExp _ignoredTagsRe = RegExp(
    r'<(?:script|style|noscript|head|svg|canvas)\b[^>]*>[\s\S]*?<\/(?:script|style|noscript|head|svg|canvas)>',
    caseSensitive: false,
  );

  static final RegExp _footnoteAsideRe = RegExp(
    r'<aside\b([^>]*id=["\x27]([^"\x27]+)["\x27][^>]*)>([\s\S]*?)<\/aside>',
    caseSensitive: false,
  );

  static final RegExp _duokanFootnoteRe = RegExp(
    r'<(?:div|p|span)\b([^>]*(?:duokan-footnote|data-wr-footnote|zy-footnote)[^>]*id=["\x27]([^"\x27]+)["\x27][^>]*)>([\s\S]*?)<\/(?:div|p|span)>',
    caseSensitive: false,
  );

  static final RegExp _citationAnchorRe = RegExp(r'^[\[\(]?[\*\d]+[\)\]]?$');

  static final RegExp _aTagRe = RegExp(
    r'<a\b[^>]*>([\s\S]*?)<\/a>',
    caseSensitive: false,
  );

  static final RegExp _supTagRe = RegExp(
    r'<sup\b[^>]*>([\s\S]*?)<\/sup>',
    caseSensitive: false,
  );

  static final RegExp _rubyRe = RegExp(
    r'<ruby\b[^>]*>(?:([\s\S]*?)<rt\b[^>]*>([\s\S]*?)<\/rt>|([\s\S]*?))<\/ruby>',
    caseSensitive: false,
  );

  static final RegExp _kanaRe = RegExp(r'[\u3040-\u309f\u30a0-\u30ff]');

  static final RegExp _blockEndRe = RegExp(
    r'<\/(?:h[1-6]|p|blockquote|li|dt|dd|pre|div|section|article)>|<br\s*\/?>',
    caseSensitive: false,
  );

  static final RegExp _allTagsRe = RegExp(r'<[^>]+>');
  static final RegExp _whitespaceRe = RegExp(r'\s+');

  /// Extracts clean display or spoken text from HTML/XHTML.
  ///
  /// When [forSpeech], [filterFootnotes], or [swapRubyForSpeech] is true:
  /// - Strips footnote content and numeric citation links (`[1]`, `*`).
  /// - Swaps Japanese `<ruby>` kanji with `<rt>` kana readings if kana is present.
  /// - Converts block boundaries to newlines.
  static String extractPageText(
    String html, {
    bool forSpeech = false,
    bool filterFootnotes = false,
    bool swapRubyForSpeech = false,
  }) {
    if (html.isEmpty) return '';

    final isSpeech = forSpeech || filterFootnotes || swapRubyForSpeech;

    // 1. Remove non-content tags (scripts, styles, svg, head, canvas)
    var cleaned = html.replaceAll(_ignoredTagsRe, '');

    // 2. Strip footnote blocks and citation numbers if for speech
    if (isSpeech) {
      cleaned = cleaned.replaceAll(_footnoteAsideRe, '');
      cleaned = cleaned.replaceAll(_duokanFootnoteRe, '');

      cleaned = cleaned.replaceAllMapped(_aTagRe, (match) {
        final inner = match.group(1) ?? '';
        final innerText = inner.replaceAll(_allTagsRe, '').trim();
        if (_citationAnchorRe.hasMatch(innerText)) {
          return '';
        }
        return match.group(0)!;
      });

      cleaned = cleaned.replaceAllMapped(_supTagRe, (match) {
        final inner = match.group(1) ?? '';
        final innerText = inner.replaceAll(_allTagsRe, '').trim();
        if (_citationAnchorRe.hasMatch(innerText)) {
          return '';
        }
        return match.group(0)!;
      });

      // 3. Handle Ruby typography: voice kana rt over kanji base when for speech
      cleaned = cleaned.replaceAllMapped(_rubyRe, (match) {
        final base = match.group(1);
        final rt = match.group(2);
        final onlyBase = match.group(3);

        if (rt != null) {
          final rtText = rt.replaceAll(_allTagsRe, '').trim();
          if (_kanaRe.hasMatch(rtText)) {
            return ' $rtText ';
          }
        }

        final effectiveBase = base ?? onlyBase ?? '';
        return effectiveBase.replaceAll(_allTagsRe, '');
      });
    }

    // 4. Replace block ending tags with newlines
    final withNewlines = cleaned.replaceAll(_blockEndRe, '\n');

    // 5. Strip all remaining HTML tags
    final stripped = withNewlines.replaceAll(_allTagsRe, '');

    // 6. Decode common HTML entities
    final decoded = decodeHtmlEntities(stripped);

    // 7. Clean up lines and excessive whitespace
    final lines = <String>[];
    for (final line in decoded.split('\n')) {
      final trimmed = line.trim().replaceAll(_whitespaceRe, ' ').trim();
      if (trimmed.isNotEmpty) {
        lines.add(trimmed);
      }
    }

    return lines.join('\n');
  }

  /// Extracts speech-conditioned plain text from [html], swapping ruby tags
  /// for kana readings and filtering out footnote bodies and citations.
  static String extractSpeechText(String html) =>
      extractPageText(html, forSpeech: true);

  /// Extracts all structured footnotes from HTML.
  static List<FootnoteItem> extractFootnotes(String html) {
    if (html.isEmpty) return const [];
    final results = <FootnoteItem>[];

    for (final match in _footnoteAsideRe.allMatches(html)) {
      final attrs = match.group(1) ?? '';
      final id = match.group(2) ?? '';
      final inner = (match.group(3) ?? '').trim();
      final fnType = attrs.toLowerCase().contains('endnote')
          ? 'endnote'
          : 'footnote';

      results.add(FootnoteItem(id: id, contentHtml: inner, type: fnType));
    }

    for (final match in _duokanFootnoteRe.allMatches(html)) {
      final id = match.group(2) ?? '';
      final inner = (match.group(3) ?? '').trim();
      if (!results.any((r) => r.id == id)) {
        results.add(FootnoteItem(id: id, contentHtml: inner, type: 'footnote'));
      }
    }

    return results;
  }

  static final RegExp _entityRe = RegExp(
    r'&(?:nbsp|amp|lt|gt|quot|#39|apos|mdash|ndash|hellip|laquo|raquo|#\d+|#x[0-9a-fA-F]+);',
    caseSensitive: false,
  );

  static const Map<String, String> _namedEntities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
    '&laquo;': '«',
    '&raquo;': '»',
  };

  static String decodeHtmlEntities(String text) {
    if (!text.contains('&')) return text;
    return text.replaceAllMapped(_entityRe, (match) {
      final entity = match.group(0)!;
      final named = _namedEntities[entity.toLowerCase()];
      if (named != null) return named;

      if (entity.startsWith('&#x') || entity.startsWith('&#X')) {
        final hexStr = entity.substring(3, entity.length - 1);
        final code = int.tryParse(hexStr, radix: 16);
        if (code != null) return String.fromCharCode(code);
      } else if (entity.startsWith('&#')) {
        final decStr = entity.substring(2, entity.length - 1);
        final code = int.tryParse(decStr);
        if (code != null) return String.fromCharCode(code);
      }

      return entity;
    });
  }
}

/// Convenience text-extraction API for reflowable documents.
extension ReflowableSectionText on ReflowableDocumentReader {
  /// Extracts plain text from the section at [index] (for display and analysis).
  String extractSectionText(int index) =>
      HtmlTextExtractor.extractPageText(loadSectionHtml(index));

  /// Extracts speech-conditioned plain text from the section at [index] (for TTS playback).
  String extractSectionSpeechText(int index) =>
      HtmlTextExtractor.extractSpeechText(loadSectionHtml(index));
}
