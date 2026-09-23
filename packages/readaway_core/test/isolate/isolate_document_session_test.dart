import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('IsolateDocumentSession Tests', () {
    late Directory tempDir;
    late File sampleEpubFile;
    late File sampleTxtFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isolate_doc_test_');

      // 1. Create a valid test EPUB file
      final archive = Archive();
      archive.addFile(
        ArchiveFile('mimetype', 20, utf8.encode('application/epub+zip')),
      );

      const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
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
    <dc:title>Isolate EPUB Book</dc:title>
    <dc:creator>Test Author</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="images/cover.jpg" media-type="image/jpeg" properties="cover-image"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
  </spine>
</package>''';
      archive.addFile(
        ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)),
      );

      const ch1Xhtml = '''<html>
<body>
  <h1>Chapter 1</h1>
  <p>Hello from background isolate!<a href="#fn1" id="ref1">1</a></p>
  <aside id="fn1" epub:type="footnote"><p>This is a footnote in isolate.</p></aside>
</body>
</html>''';
      archive.addFile(
        ArchiveFile(
          'OEBPS/chapter1.xhtml',
          ch1Xhtml.length,
          utf8.encode(ch1Xhtml),
        ),
      );

      final fakeImageBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      archive.addFile(
        ArchiveFile(
          'OEBPS/images/cover.jpg',
          fakeImageBytes.length,
          fakeImageBytes,
        ),
      );

      final zipBytes = ZipEncoder().encode(archive);
      sampleEpubFile = File(p.join(tempDir.path, 'sample.epub'));
      await sampleEpubFile.writeAsBytes(zipBytes);

      // 2. Create a test TXT file
      const txtContent = '''《Test Novel》Author: Writer

Chapter 1: The Beginning
Sample plain text in isolate.

Chapter 2: The End
Final text in isolate.
''';
      sampleTxtFile = File(p.join(tempDir.path, 'Test Novel.txt'));
      await sampleTxtFile.writeAsString(txtContent);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'opens EPUB document on background isolate and reads properties',
      () async {
        final session = await IsolateDocumentSession.open(sampleEpubFile.path);

        expect(session.format, 'epub');
        expect(session.isReflowable, isTrue);
        expect(session.title, 'Isolate EPUB Book');
        expect(session.metadata?.author, 'Test Author');
        expect(session.sectionCount, 1);
        expect(session.coverImagePath, 'OEBPS/images/cover.jpg');

        // Load section HTML
        final html = await session.loadSectionHtml(0);
        expect(html, contains('Hello from background isolate!'));

        // Extract section text
        final text = await session.extractSectionText(0);
        expect(text, contains('Hello from background isolate!'));

        // Extract speech text
        final speech = await session.extractSectionSpeechText(0);
        expect(speech, contains('Hello from background isolate!'));

        // Resolve footnote
        final fn = await session.resolveFootnote(
          '#fn1',
          currentChapterIndex: 0,
        );
        expect(fn, isNotNull);
        expect(fn?.contentHtml, contains('This is a footnote in isolate.'));

        // Load asset with TransferableTypedData
        final assetBytes = await session.loadAsset('OEBPS/images/cover.jpg');
        expect(assetBytes, isNotNull);
        expect(assetBytes, Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]));

        // Resolve section index
        final idx = await session.resolveSectionIndex('OEBPS/chapter1.xhtml');
        expect(idx, 0);

        // Dispose session
        session.dispose();
        expect(session.isDisposed, isTrue);
        expect(() => session.loadSectionHtml(0), throwsA(isA<StateError>()));
      },
    );

    test(
      'opens TXT document on background isolate and parses sections',
      () async {
        final session = await IsolateDocumentSession.open(sampleTxtFile.path);

        expect(session.format, 'txt');
        expect(session.isReflowable, isTrue);
        expect(session.title, 'Test Novel');
        expect(session.metadata?.author, 'Writer');
        expect(session.sectionCount, 3);

        final ch1 = await session.loadSectionHtml(1);
        expect(ch1, contains('Chapter 1: The Beginning'));
        expect(ch1, contains('Sample plain text in isolate.'));

        session.dispose();
      },
    );

    test(
      'throws DocumentOpenException on invalid or non-existent file',
      () async {
        expect(
          () => IsolateDocumentSession.open(
            p.join(tempDir.path, 'non_existent.epub'),
          ),
          throwsA(isA<DocumentOpenException>()),
        );
      },
    );
  });
}
