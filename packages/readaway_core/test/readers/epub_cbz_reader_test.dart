import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('Pure Dart EPUB & CBZ Readers', () {
    test('EpubDocumentReader opens in-memory EPUB and parses metadata, spine, TOC, and HTML', () async {
      final archive = Archive();

      // 1. mimetype
      archive.addFile(
        ArchiveFile('mimetype', 20, utf8.encode('application/epub+zip')),
      );

      // 2. container.xml
      const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      archive.addFile(
        ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)),
      );

      // 3. content.opf
      const opfXml = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test EPUB Book</dc:title>
    <dc:creator>Author Person</dc:creator>
    <dc:language>en</dc:language>
    <dc:identifier id="pub-id">test-id-123</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="images/cover.jpg" media-type="image/jpeg" properties="cover-image"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''';
      archive.addFile(
        ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)),
      );

      // 4. nav.xhtml
      const navXhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="chapter1.xhtml">Chapter 1: Start</a></li>
        <li><a href="chapter2.xhtml">Chapter 2: Finish</a></li>
      </ol>
    </nav>
  </body>
</html>''';
      archive.addFile(
        ArchiveFile('OEBPS/nav.xhtml', navXhtml.length, utf8.encode(navXhtml)),
      );

      // 5. chapters
      const ch1Xhtml = '''<html><body><h1>Chapter 1</h1><p>Welcome to the book.</p></body></html>''';
      const ch2Xhtml = '''<html><body><h1>Chapter 2</h1><p>The end of the book.</p></body></html>''';
      archive.addFile(
        ArchiveFile('OEBPS/chapter1.xhtml', ch1Xhtml.length, utf8.encode(ch1Xhtml)),
      );
      archive.addFile(
        ArchiveFile('OEBPS/chapter2.xhtml', ch2Xhtml.length, utf8.encode(ch2Xhtml)),
      );

      // 6. image asset
      final fakeImageBytes = [0xFF, 0xD8, 0xFF, 0xE0];
      archive.addFile(
        ArchiveFile('OEBPS/images/cover.jpg', fakeImageBytes.length, fakeImageBytes),
      );

      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);

      final reader = await EpubDocumentReader.fromBytes(Uint8List.fromList(zipBytes));

      expect(reader.format, 'epub');
      expect(reader.isReflowable, isTrue);
      expect(reader.title, 'Test EPUB Book');
      expect(reader.metadata?.author, 'Author Person');
      expect(reader.metadata?.language, 'en');
      expect(reader.metadata?.identifier, 'test-id-123');
      expect(reader.coverImagePath, 'OEBPS/images/cover.jpg');

      expect(reader.sectionCount, 2);
      expect(reader.sections[0].href, 'OEBPS/chapter1.xhtml');
      expect(reader.sections[1].href, 'OEBPS/chapter2.xhtml');

      expect(reader.outline.length, 2);
      expect(reader.outline[0].title, 'Chapter 1: Start');
      expect(reader.outline[1].title, 'Chapter 2: Finish');

      final ch1 = reader.loadSectionHtml(0);
      expect(ch1, contains('Welcome to the book.'));

      final ch2 = reader.loadSectionHtml(1);
      expect(ch2, contains('The end of the book.'));

      final asset = reader.loadAsset('OEBPS/images/cover.jpg');
      expect(asset, isNotNull);
      expect(asset!.length, 4);

      expect(reader.resolveSectionIndex('chapter2.xhtml'), 1);
      expect(reader.resolveSectionIndex('OEBPS/chapter1.xhtml'), 0);

      expect(reader.resolveAssetPath(0, 'images/cover.jpg'), 'OEBPS/images/cover.jpg');

      reader.dispose();
      expect(() => reader.loadSectionHtml(0), throwsA(isA<DocumentDisposedException>()));
    });

    test('CbzDocumentReader opens in-memory CBZ with natural sort', () async {
      final archive = Archive();
      final dummyImg = [0x89, 0x50, 0x4E, 0x47];

      archive.addFile(ArchiveFile('page_10.png', dummyImg.length, dummyImg));
      archive.addFile(ArchiveFile('page_1.png', dummyImg.length, dummyImg));
      archive.addFile(ArchiveFile('page_2.png', dummyImg.length, dummyImg));
      archive.addFile(ArchiveFile('page_20.png', dummyImg.length, dummyImg));

      final zipBytes = ZipEncoder().encode(archive);
      final reader = await CbzDocumentReader.fromBytes(
        Uint8List.fromList(zipBytes),
        filePath: 'comic.cbz',
      );

      expect(reader.format, 'cbz');
      expect(reader.isReflowable, isFalse);
      expect(reader.pageCount, 4);
      expect(reader.pagePaths, ['page_1.png', 'page_2.png', 'page_10.png', 'page_20.png']);

      final p0 = reader.loadPageSync(0);
      expect(p0.length, 4);

      reader.dispose();
      expect(() => reader.loadPageSync(0), throwsA(isA<DocumentDisposedException>()));
    });
  });
}
