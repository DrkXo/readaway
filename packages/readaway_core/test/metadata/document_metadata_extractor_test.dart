import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('DocumentMetadataExtractor Tests', () {
    late Directory tempDir;
    late File sampleEpubFile;
    late File sampleTxtFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'metadata_extractor_test_',
      );

      // Create a valid test EPUB file
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
    <dc:title>Great Novel</dc:title>
    <dc:creator>Jane Doe</dc:creator>
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
  <p>First paragraph of great novel.</p>
</body>
</html>''';
      archive.addFile(
        ArchiveFile(
          'OEBPS/chapter1.xhtml',
          ch1Xhtml.length,
          utf8.encode(ch1Xhtml),
        ),
      );

      final dummyJpgBytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
      ]);
      archive.addFile(
        ArchiveFile(
          'OEBPS/images/cover.jpg',
          dummyJpgBytes.length,
          dummyJpgBytes,
        ),
      );

      final zipData = ZipEncoder().encode(archive);
      sampleEpubFile = File(p.join(tempDir.path, 'sample.epub'));
      await sampleEpubFile.writeAsBytes(zipData);

      sampleTxtFile = File(p.join(tempDir.path, 'plain.txt'));
      await sampleTxtFile.writeAsString('Just a simple text file.');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('extracts metadata and cover from EPUB', () async {
      final meta = await DocumentMetadataExtractor.extract(sampleEpubFile.path);

      expect(meta.title, 'Great Novel');
      expect(meta.author, 'Jane Doe');
      expect(meta.format, 'epub');
      expect(meta.isReflowable, isTrue);
      expect(meta.pageCount, 1);
      expect(meta.coverImagePath, isNotNull);
      expect(meta.coverImageBytes, isNotNull);
      expect(meta.coverImageBytes!.isNotEmpty, isTrue);
    });

    test('extracts metadata from plain text file', () async {
      final meta = await DocumentMetadataExtractor.extract(sampleTxtFile.path);

      expect(meta.title, 'plain');
      expect(meta.author, isNull);
      expect(meta.format, 'txt');
      expect(meta.pageCount, 1);
      expect(meta.coverImageBytes, isNull);
    });
  });
}
