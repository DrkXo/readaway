import 'dart:convert';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('NavParser', () {
    const parser = NavParser();

    test('parses the toc nav into top-level items', () {
      final bytes = utf8.encode('''
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="chapter1.xhtml">Chapter One</a></li>
        <li><a href="chapter2.xhtml">Chapter Two</a></li>
      </ol>
    </nav>
  </body>
</html>
''');

      final outline = parser.parse(bytes);

      expect(outline, hasLength(2));
      expect(outline[0].title, 'Chapter One');
      expect(outline[0].href, 'chapter1.xhtml');
      expect(outline[0].level, 0);
    });

    test('parses nested lists into a hierarchy', () {
      final bytes = utf8.encode('''
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li>
          <a href="part1.xhtml">Part I</a>
          <ol>
            <li><a href="section-a.xhtml">Section A</a></li>
          </ol>
        </li>
      </ol>
    </nav>
  </body>
</html>
''');

      final outline = parser.parse(bytes);

      expect(outline, hasLength(1));
      expect(outline[0].children, hasLength(1));
      expect(outline[0].children[0].title, 'Section A');
      expect(outline[0].children[0].level, 1);
    });

    test('falls back to the first nav when no toc nav exists', () {
      final bytes = utf8.encode('''
<html xmlns="http://www.w3.org/1999/xhtml">
  <body>
    <nav>
      <ol>
        <li><a href="page.xhtml">Page</a></li>
      </ol>
    </nav>
  </body>
</html>
''');

      final outline = parser.parse(bytes);
      expect(outline, hasLength(1));
      expect(outline[0].title, 'Page');
    });

    test('returns empty list when no nav elements exist', () {
      final bytes = utf8.encode('<html><body><p>no nav</p></body></html>');
      expect(parser.parse(bytes), isEmpty);
    });
  });
}
