import 'dart:convert';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('NcxParser', () {
    const parser = NcxParser();

    test('parses a flat navMap into top-level items', () {
      final bytes = utf8.encode('''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>Chapter One</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
    <navPoint id="np2" playOrder="2">
      <navLabel><text>Chapter Two</text></navLabel>
      <content src="chapter2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>
''');

      final outline = parser.parse(bytes);

      expect(outline, hasLength(2));
      expect(outline[0].title, 'Chapter One');
      expect(outline[0].href, 'chapter1.xhtml');
      expect(outline[0].level, 0);
      expect(outline[1].title, 'Chapter Two');
    });

    test('parses nested navPoints into a hierarchy', () {
      final bytes = utf8.encode('''
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/">
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>Part I</text></navLabel>
      <content src="part1.xhtml"/>
      <navPoint id="np1a" playOrder="2">
        <navLabel><text>Section A</text></navLabel>
        <content src="section-a.xhtml"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>
''');

      final outline = parser.parse(bytes);

      expect(outline, hasLength(1));
      expect(outline[0].title, 'Part I');
      expect(outline[0].children, hasLength(1));
      expect(outline[0].children[0].title, 'Section A');
      expect(outline[0].children[0].level, 1);
      expect(outline[0].flatten(), hasLength(2));
    });

    test('applies resolveHref callback', () {
      final bytes = utf8.encode('''
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/">
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>Chapter</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>
''');

      final outline = parser.parse(bytes, resolveHref: (src) => 'OEBPS/$src');

      expect(outline[0].href, 'OEBPS/chapter1.xhtml');
    });

    test('returns empty list when no navMap is present', () {
      final bytes = utf8.encode(
        '<ncx><docTitle><text>x</text></docTitle></ncx>',
      );
      expect(parser.parse(bytes), isEmpty);
    });
  });
}
