import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('Comic Readers & ImageHeaderParser', () {
    test('ImageHeaderParser extracts dimensions from PNG headers', () {
      // 1x1 PNG header bytes
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // Signature
        0x00, 0x00, 0x00, 0x0D, // IHDR chunk len = 13
        0x49, 0x48, 0x44, 0x52, // "IHDR"
        0x00, 0x00, 0x03, 0x20, // Width = 800
        0x00, 0x00, 0x04, 0xB0, // Height = 1200
        0x08, 0x06, 0x00, 0x00, 0x00,
      ]);

      final size = ImageHeaderParser.parseDimensions(pngBytes);
      expect(size, isNotNull);
      if (size != null) {
        expect(size.width, 800.0);
        expect(size.height, 1200.0);
        expect(size.aspectRatio, closeTo(800 / 1200, 0.001));
      }
    });

    test('ImageHeaderParser extracts dimensions from JPEG headers', () {
      // Minimal JPEG SOF0 header
      final jpegBytes = Uint8List.fromList([
        0xFF, 0xD8, // SOI
        0xFF, 0xC0, // SOF0
        0x00, 0x11, // Length = 17
        0x08, // Precision
        0x02, 0x58, // Height = 600
        0x01, 0x90, // Width = 400
        0x03, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
        0xFF, 0xD9, // EOI
      ]);

      final size = ImageHeaderParser.parseDimensions(jpegBytes);
      expect(size, isNotNull);
      if (size != null) {
        expect(size.width, 400.0);
        expect(size.height, 600.0);
      }
    });

    test('ImageHeaderParser extracts dimensions from GIF headers', () {
      final gifBytes = Uint8List.fromList([
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // "GIF89a"
        0x2C, 0x01, // Width = 300 (little endian: 0x012C)
        0x90, 0x01, // Height = 400 (little endian: 0x0190)
        0x80, 0x00, 0x00,
      ]);

      final size = ImageHeaderParser.parseDimensions(gifBytes);
      expect(size, isNotNull);
      if (size != null) {
        expect(size.width, 300.0);
        expect(size.height, 400.0);
      }
    });

    test('ComicBookDocumentReader parses CBZ with ComicInfo.xml metadata and bookmarks', () async {
      final archive = Archive();

      // PNG page 1 (800x1200)
      final p1 = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x03, 0x20, // 800
        0x00, 0x00, 0x04, 0xB0, // 1200
        0x08, 0x06, 0x00, 0x00, 0x00,
      ]);

      // PNG page 2 (800x1200)
      final p2 = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x03,
        0x20,
        0x00,
        0x00,
        0x04,
        0xB0,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
      ]);

      const comicInfoXml = '''<?xml version="1.0"?>
<ComicInfo xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Title>The Beginning</Title>
  <Series>Epic Saga</Series>
  <Number>1</Number>
  <Summary>A grand adventure begins.</Summary>
  <Writer>Jane Doe</Writer>
  <Penciller>John Artist</Penciller>
  <Publisher>Comics Corp</Publisher>
  <Pages>
    <Page Image="0" Type="Cover" Bookmark="Front Cover"/>
    <Page Image="1" Type="Story" Bookmark="Chapter 1"/>
  </Pages>
</ComicInfo>''';

      archive.addFile(
        ArchiveFile(
          'ComicInfo.xml',
          comicInfoXml.length,
          utf8.encode(comicInfoXml),
        ),
      );
      archive.addFile(ArchiveFile('page_10.png', p2.length, p2));
      archive.addFile(ArchiveFile('page_01.png', p1.length, p1));

      final zipBytes = ZipEncoder().encode(archive);
      final reader = await ComicBookDocumentReader.fromBytes(
        Uint8List.fromList(zipBytes),
        filePath: 'saga_01.cbz',
      );

      expect(reader.format, 'cbz');
      expect(reader.isReflowable, isFalse);
      expect(reader.pageCount, 2);
      expect(reader.pagePaths, ['page_01.png', 'page_10.png']);
      expect(reader.title, 'The Beginning');
      expect(reader.metadata?.author, 'Jane Doe, Art: John Artist');
      expect(reader.metadata?.description, 'A grand adventure begins.');
      expect(reader.outline.length, 2);
      expect(reader.outline[0].title, 'Front Cover');
      expect(reader.outline[1].title, 'Chapter 1');

      final size0 = reader.getPageSize(0);
      expect(size0?.width, 800.0);
      expect(size0?.height, 1200.0);

      final p0Bytes = await reader.loadPageImage(0);
      expect(p0Bytes.length, p1.length);
      expect(reader.getCachedPageImage(0), isNotNull);

      reader.dispose();
      expect(
        () => reader.loadPageSync(0),
        throwsA(isA<DocumentDisposedException>()),
      );
    });

    test('TarComicArchiveAdapter opens CBT archives', () async {
      final archive = Archive();
      final dummyImg = [0x89, 0x50, 0x4E, 0x47];

      archive.addFile(ArchiveFile('img_02.png', dummyImg.length, dummyImg));
      archive.addFile(ArchiveFile('img_01.png', dummyImg.length, dummyImg));

      final tarBytes = TarEncoder().encode(archive);
      final reader = await ComicBookDocumentReader.fromBytes(
        Uint8List.fromList(tarBytes),
        filePath: 'comic.cbt',
      );

      expect(reader.format, 'cbt');
      expect(reader.isReflowable, isFalse);
      expect(reader.pageCount, 2);
      expect(reader.pagePaths, ['img_01.png', 'img_02.png']);

      final p0 = reader.loadPageSync(0);
      expect(p0.length, dummyImg.length);

      reader.dispose();
    });

    test(
      'ComicTocExtractor extracts hierarchy from folders and chapter patterns',
      () {
        // 1. Folder structure
        final folderPaths = [
          'Vol 1/Ch 1/01.jpg',
          'Vol 1/Ch 1/02.jpg',
          'Vol 1/Ch 2/01.jpg',
          'Vol 2/Ch 1/01.jpg',
        ];
        final folderOutline = ComicTocExtractor.extract(folderPaths);
        expect(folderOutline.length, 2);
        expect(folderOutline[0].title, 'Vol 1');
        expect(folderOutline[0].chapterIndex, 0);
        expect(folderOutline[0].children.length, 2);
        expect(folderOutline[0].children[0].title, 'Ch 1');
        expect(folderOutline[0].children[0].chapterIndex, 0);
        expect(folderOutline[0].children[1].title, 'Ch 2');
        expect(folderOutline[0].children[1].chapterIndex, 2);
        expect(folderOutline[1].title, 'Vol 2');
        expect(folderOutline[1].chapterIndex, 3);

        // 2. Chapter pattern in filenames
        final chapterPaths = [
          'Manga_Ch.01_p01.jpg',
          'Manga_Ch.01_p02.jpg',
          'Manga_Ch.02_p01.jpg',
        ];
        final chapterOutline = ComicTocExtractor.extract(chapterPaths);
        expect(chapterOutline.length, 2);
        expect(chapterOutline[0].title, 'Chapter 01');
        expect(chapterOutline[0].chapterIndex, 0);
        expect(chapterOutline[1].title, 'Chapter 02');
        expect(chapterOutline[1].chapterIndex, 2);

        // 3. Fallback page names
        final pagePaths = [
          'exampleCBZ.jpg',
          'example.jpeg',
          'example.jpg',
          'example.png',
        ];
        final pageOutline = ComicTocExtractor.extract(pagePaths);
        expect(pageOutline.length, 4);
        expect(pageOutline[0].title, 'exampleCBZ');
        expect(pageOutline[0].chapterIndex, 0);
        expect(pageOutline[1].title, 'example');
        expect(pageOutline[1].chapterIndex, 1);
        expect(pageOutline[2].title, 'example (2)');
        expect(pageOutline[2].chapterIndex, 2);
        expect(pageOutline[3].title, 'example (3)');
        expect(pageOutline[3].chapterIndex, 3);
      },
    );

    test(
      'ComicBookDocumentReader generates outline for dynamic CBZ (example.cbz)',
      () async {
        const exampleCbzPath = '/home/drkxo/Documents/Ebooks/example.cbz';
        if (!File(exampleCbzPath).existsSync()) return;

        final reader = await ComicBookDocumentReader.open(exampleCbzPath);
        try {
          expect(reader.format, 'cbz');
          expect(reader.pageCount, 4);
          expect(reader.outline, isNotEmpty);
          expect(reader.outline.length, 4);
          expect(reader.outline[0].title, 'example');
          expect(reader.outline[0].chapterIndex, 0);
          expect(reader.outline[0].href, 'page:0');
          expect(reader.outline[1].title, 'example (2)');
          expect(reader.outline[1].chapterIndex, 1);
          expect(reader.outline[2].title, 'example (3)');
          expect(reader.outline[2].chapterIndex, 2);
          expect(reader.outline[3].title, 'exampleCBZ');
          expect(reader.outline[3].chapterIndex, 3);
        } finally {
          reader.dispose();
        }
      },
    );
  });
}
