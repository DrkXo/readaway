import 'package:html/parser.dart' as html_parser;

import '../models/models.dart';
import 'text_transformer.dart';

/// Identifies, normalizes, and extracts footnotes, endnotes, and asides
/// across standard EPUB 3, Duokan, WeChat Read, and Zhangyue ebook formats.
class FootnoteTransformer implements TextTransformer {
  const FootnoteTransformer();

  @override
  String get name => 'footnote';

  static final RegExp _asideEpubTypeRegex = RegExp(
    r'<aside\s+([^>]*\bepub:type\s*=\s*["\x27](footnote|endnote|note|rearnote)["\x27][^>]*)>',
    caseSensitive: false,
  );

  @override
  String transform(TransformContext context) {
    var result = context.content;

    // Inject 'epubtype-footnote' class into <aside epub:type="..."> tags
    result = result.replaceAllMapped(_asideEpubTypeRegex, (m) {
      final attrs = m.group(1)!;
      if (attrs.contains('epubtype-footnote')) {
        return '<aside $attrs>';
      }
      if (attrs.contains('class=')) {
        return '<aside ${attrs.replaceFirstMapped(RegExp(r'class=(["\x27])'), (cm) => 'class=${cm.group(1)}epubtype-footnote ')}>';
      }
      return '<aside class="epubtype-footnote" $attrs>';
    });

    return result;
  }

  /// Extracts structured [FootnoteItem] records from the chapter HTML.
  static List<FootnoteItem> extractFootnotes(String html) {
    if (html.isEmpty) return const [];
    final doc = html_parser.parse(html);
    final results = <FootnoteItem>[];

    // 1. Standard EPUB 3 <aside epub:type="footnote|endnote|note|rearnote">
    final asides = doc.querySelectorAll('aside');
    for (final aside in asides) {
      final epubType = aside.attributes['epub:type']?.toLowerCase() ?? '';
      if (epubType.contains('footnote') ||
          epubType.contains('endnote') ||
          epubType.contains('note') ||
          aside.classes.contains('epubtype-footnote')) {
        final id = aside.id.isNotEmpty
            ? aside.id
            : 'fn-${results.length + 1}';
        results.add(
          FootnoteItem(
            id: id,
            contentHtml: aside.innerHtml.trim(),
            type: epubType.contains('endnote') ? 'endnote' : 'footnote',
          ),
        );
      }
    }

    // 2. Duokan footnote items (.duokan-footnote-content, .duokan-footnote-item)
    final duokanNotes = doc.querySelectorAll(
      '.duokan-footnote-content, .duokan-footnote-item, [data-wr-footernote], [zy-footnote]',
    );
    for (final note in duokanNotes) {
      final id = note.id.isNotEmpty
          ? note.id
          : 'duokan-fn-${results.length + 1}';
      if (!results.any((fn) => fn.id == id)) {
        results.add(
          FootnoteItem(
            id: id,
            contentHtml: note.innerHtml.trim(),
            type: 'footnote',
          ),
        );
      }
    }

    return results;
  }
}
