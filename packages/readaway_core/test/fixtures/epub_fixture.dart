import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Builds an in-memory EPUB for tests using `package:archive`.
class EpubFixture {
  const EpubFixture._();

  /// Builds a valid EPUB with [chapterCount] chapters.
  ///
  /// Includes an NCX (EPUB 2) and `<nav>` (EPUB 3) outline by default, plus a
  /// binary asset at `OEBPS/images/cover.png`.
  static Uint8List build({
    bool includeNcx = true,
    bool includeNav = true,
    bool includeCover = true,
    int chapterCount = 2,
  }) {
    final archive = Archive();

    void addText(String path, String content) {
      archive.addFile(ArchiveFile.string(path, content));
    }

    addText('mimetype', 'application/epub+zip');
    addText('META-INF/container.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''');

    final manifest = StringBuffer();
    final spine = StringBuffer();
    for (var i = 1; i <= chapterCount; i++) {
      manifest.write(
        '    <item id="chapter$i" href="chapter$i.xhtml" '
        'media-type="application/xhtml+xml"/>\n',
      );
      spine.write('    <itemref idref="chapter$i"/>\n');
      addText(
        'OEBPS/chapter$i.xhtml',
        '<html xmlns="http://www.w3.org/1999/xhtml">'
            '<head><title>Chapter $i</title></head>'
            '<body><h1>Chapter $i</h1><p>Content of chapter $i.</p></body>'
            '</html>',
      );
    }
    if (includeNcx) {
      manifest.write(
        '    <item id="ncx" href="toc.ncx" '
        'media-type="application/x-dtbncx+xml"/>\n',
      );
      addText('OEBPS/toc.ncx', _ncx(chapterCount));
    }
    if (includeNav) {
      manifest.write(
        '    <item id="nav" href="nav.xhtml" '
        'media-type="application/xhtml+xml" properties="nav"/>\n',
      );
      addText('OEBPS/nav.xhtml', _nav(chapterCount));
    }
    if (includeCover) {
      manifest.write(
        '    <item id="cover" href="images/cover.png" '
        'media-type="image/png" properties="cover-image"/>\n',
      );
    }

    addText('OEBPS/content.opf', '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/">
    <dc:identifier id="book-id">urn:uuid:test-book</dc:identifier>
    <dc:title>Test Book</dc:title>
    <dc:creator>Test Author</dc:creator>
    <dc:language>en</dc:language>
    <dc:publisher>Test Publisher</dc:publisher>
    <meta property="dcterms:modified">2024-01-01T00:00:00Z</meta>
  </metadata>
  <manifest>
$manifest  </manifest>
  <spine>
$spine  </spine>
</package>''');

    archive.addFile(
      ArchiveFile.bytes(
        'OEBPS/images/cover.png',
        Uint8List.fromList([1, 2, 3, 4]),
      ),
    );

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  static String _ncx(int chapterCount) {
    final navPoints = StringBuffer();
    for (var i = 1; i <= chapterCount; i++) {
      navPoints.write('''    <navPoint id="navPoint-$i" playOrder="$i">
      <navLabel><text>Chapter $i</text></navLabel>
      <content src="chapter$i.xhtml"/>
    </navPoint>
''');
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="urn:uuid:test-book"/></head>
  <docTitle><text>Test Book</text></docTitle>
  <navMap>
$navPoints  </navMap>
</ncx>''';
  }

  static String _nav(int chapterCount) {
    final items = StringBuffer();
    for (var i = 1; i <= chapterCount; i++) {
      items.write('      <li><a href="chapter$i.xhtml">Chapter $i</a></li>\n');
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>Table of Contents</title></head>
  <body>
    <nav epub:type="toc">
      <h1>Table of Contents</h1>
      <ol>
$items      </ol>
    </nav>
  </body>
</html>''';
  }
}

/// Decodes [bytes] back to a UTF-8 string (test helper).
String decodeUtf8(Uint8List bytes) => utf8.decode(bytes);
