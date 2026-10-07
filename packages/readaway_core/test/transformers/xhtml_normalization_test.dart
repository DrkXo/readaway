import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('XHTML Self-Closing Normalization', () {
    const transformer = HtmlCleanupTransformer();

    test('normalizes self-closing script and style tags into paired tags', () {
      const input =
          '<html><head><script src="js/book.js"/><style type="text/css"/></head><body><p>Hello World</p></body></html>';
      final result = transformer.transform(
        const TransformContext(content: input),
      );

      expect(result, contains('<script src="js/book.js"></script>'));
      expect(result, contains('<style type="text/css"></style>'));
      expect(result, contains('<p>Hello World</p>'));
    });

    test('normalizes self-closing div and span elements into paired tags', () {
      const input =
          '<div><div style="width:1px;"/><p><span id="ch1"/>Chapter 1</p></div>';
      final result = transformer.transform(
        const TransformContext(content: input),
      );

      expect(result, contains('<div style="width: 1px"></div>'));
      expect(result, contains('<span id="ch1"></span>'));
      expect(result, contains('Chapter 1'));
    });

    test('preserves valid HTML5 void elements with self-closing slashes', () {
      const input =
          '<div><img src="cover.jpg" /><br/><hr/><meta charset="utf-8"/><link rel="stylesheet" href="style.css"/></div>';
      final result = transformer.transform(
        const TransformContext(content: input),
      );

      expect(result, contains('<img src="cover.jpg" />'));
      expect(result, contains('<br/>'));
      expect(result, contains('<hr/>'));
      expect(result, contains('<meta charset="utf-8"/>'));
      expect(result, contains('<link rel="stylesheet" href="style.css"/>'));
    });
  });

  group('HtmlTextExtractor with self-closing tags', () {
    test('ignores self-closing script and style tags without swallowing text', () {
      const input =
          '<html><head><script src="js/book.js"/><style type="text/css"/></head><body><p>Story Text</p></body></html>';
      final text = HtmlTextExtractor.extractPageText(input);

      expect(text.trim(), equals('Story Text'));
    });
  });

  group('EpubDocumentReader XHTML normalization', () {
    test(
      'loadSectionHtml normalizes self-closing script tags in chapter XHTML',
      () async {
        final archive = Archive();

        archive.addFile(
          ArchiveFile('mimetype', 20, utf8.encode('application/epub+zip')),
        );

        const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
        archive.addFile(
          ArchiveFile(
            'META-INF/container.xml',
            containerXml.length,
            utf8.encode(containerXml),
          ),
        );

        const opfXml = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>XHTML Test EPUB</dc:title>
    <dc:identifier id="pub-id">test-xhtml-1</dc:identifier>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
  </spine>
</package>''';
        archive.addFile(
          ArchiveFile('OPS/content.opf', opfXml.length, utf8.encode(opfXml)),
        );

        const ch1Xhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Chapter 1</title>
    <script src="js/book.js"/>
  </head>
  <body>
    <h1>Chapter 1 Title</h1>
    <p>Chapter 1 Body</p>
  </body>
</html>''';
        archive.addFile(
          ArchiveFile('OPS/ch1.xhtml', ch1Xhtml.length, utf8.encode(ch1Xhtml)),
        );

        final reader = await EpubDocumentReader.fromBytes(
          Uint8List.fromList(ZipEncoder().encode(archive)),
          filePath: 'test_xhtml.epub',
        );

        final loadedHtml = reader.loadSectionHtml(0);
        expect(loadedHtml, contains('<script src="js/book.js"></script>'));
        expect(loadedHtml, isNot(contains('<script src="js/book.js"/>')));

        final extractedText = HtmlTextExtractor.extractPageText(loadedHtml);
        expect(extractedText, contains('Chapter 1 Title'));
        expect(extractedText, contains('Chapter 1 Body'));
      },
    );
  });
}
