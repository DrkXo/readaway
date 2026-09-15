import '../models/footnote_item.dart';
import '../models/transform_context.dart';
import '../rust/api/tts.dart' as tts_api;
import 'text_transformer.dart';

/// Identifies, normalizes, and extracts footnotes, endnotes, and asides backed by native Rust.
class FootnoteTransformer implements TextTransformer {
  const FootnoteTransformer();

  @override
  String get name => 'footnote';

  RegExp get _asideEpubTypeRegex => RegExp(
        r'<aside\s+([^>]*\bepub:type\s*=\s*["\x27](footnote|endnote|note|rearnote)["\x27][^>]*)>',
        caseSensitive: false,
      );

  @override
  String transform(TransformContext context) {
    var result = context.content;

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

  /// Extracts structured [FootnoteItem] records from the chapter HTML using native Rust.
  static List<FootnoteItem> extractFootnotes(String html) {
    if (html.isEmpty) return const [];
    try {
      return tts_api
          .extractHtmlContent(html: html)
          .footnotes
          .map(FootnoteItem.fromRust)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Searches [html] for a footnote matching [anchorId].
  static FootnoteItem? findFootnote(String html, String anchorId) {
    if (html.isEmpty || anchorId.isEmpty) return null;
    final cleanId = anchorId.startsWith('#') ? anchorId.substring(1) : anchorId;
    if (cleanId.isEmpty) return null;

    final notes = extractFootnotes(html);
    for (final note in notes) {
      if (note.id == cleanId) {
        return note;
      }
    }

    return null;
  }
}

