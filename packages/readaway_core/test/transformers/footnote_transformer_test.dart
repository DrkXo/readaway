import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('FootnoteTransformer', () {
    const transformer = FootnoteTransformer();

    test('tags EPUB 3 aside footnotes with epubtype-footnote class', () {
      const html = '<aside id="fn-1" epub:type="footnote"><p>Footnote content</p></aside>';
      final ctx = TransformContext(content: html);

      final result = transformer.transform(ctx);
      expect(result, contains('class="epubtype-footnote"'));
      expect(result, contains('epub:type="footnote"'));
    });

    test('extracts structured footnotes from EPUB and Duokan notes', () {
      const html = '''
        <p>Main text reference<sup><a href="#fn-1">[1]</a></sup>.</p>
        <aside id="fn-1" epub:type="footnote"><p>EPUB Note 1</p></aside>
        <div id="duokan-1" class="duokan-footnote-content"><p>Duokan Note 1</p></div>
      ''';

      final footnotes = FootnoteTransformer.extractFootnotes(html);
      expect(footnotes.length, equals(2));
      expect(footnotes[0].id, equals('fn-1'));
      expect(footnotes[0].contentHtml, contains('EPUB Note 1'));
      expect(footnotes[0].type, equals('footnote'));

      expect(footnotes[1].id, equals('duokan-1'));
      expect(footnotes[1].contentHtml, contains('Duokan Note 1'));
    });
  });
}
