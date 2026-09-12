import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

import '../fixtures/cbz_fixture.dart';

void main() {
  group('CbzDocumentReader', () {
    test('opens a CBZ and reports page count', () {
      final reader = CbzDocumentReader.fromBytes(CbzFixture.build());

      expect(reader.format, 'cbz');
      expect(reader.isReflowable, isFalse);
      expect(reader.pageCount, 3);
      expect(reader.title, isNull);
      expect(reader.metadata, isNull);
      expect(reader.outline, isEmpty);

      reader.dispose();
    });

    test('sorts pages naturally (page2 before page10)', () {
      final reader = CbzDocumentReader.fromBytes(
        CbzFixture.build(pageNames: ['page10.png', 'page2.png', 'page1.png']),
      );

      expect(reader.pageCount, 3);
      expect(reader.coverImagePath, 'page1.png');

      reader.dispose();
    });

    test('excludes non-image entries', () {
      final reader = CbzDocumentReader.fromBytes(CbzFixture.build());

      // ComicInfo.xml is not a page but remains loadable as an asset.
      expect(reader.pageCount, 3);
      expect(reader.loadAsset('ComicInfo.xml'), isNotNull);

      reader.dispose();
    });

    test('renders a page to RGBA pixels', () async {
      final reader = CbzDocumentReader.fromBytes(CbzFixture.build());

      final page = await reader.renderPage(0);
      expect(page.width, 4);
      expect(page.height, 4);
      expect(page.components, 4);
      expect(page.stride, 4 * 4);
      expect(page.pixels.length, 4 * 4 * 4);

      reader.dispose();
    });

    test('renderPage respects scale', () async {
      final reader = CbzDocumentReader.fromBytes(CbzFixture.build());

      final page = await reader.renderPage(0, scaleX: 2.0, scaleY: 2.0);
      expect(page.width, 8);
      expect(page.height, 8);

      reader.dispose();
    });

    test('extractHtml embeds the page image', () async {
      final reader = CbzDocumentReader.fromBytes(CbzFixture.build());

      final html = await reader.extractHtml(0);
      expect(html, contains('<img'));
      expect(html, contains('data:image/png;base64,'));

      reader.dispose();
    });

    test('extractText/search/pageLinks/resolvePage are empty', () async {
      final reader = CbzDocumentReader.fromBytes(CbzFixture.build());

      expect(await reader.extractText(0), isEmpty);
      expect(await reader.search(0, 'x'), isEmpty);
      expect(await reader.pageLinks(0), isEmpty);
      expect(await reader.resolvePage('x'), isNull);

      reader.dispose();
    });

    test('throws DocumentParseException when no images present', () {
      expect(
        () => CbzDocumentReader.fromBytes(_zipWithoutImages()),
        throwsA(isA<DocumentParseException>()),
      );
    });

    test('throws DocumentDisposedException after dispose', () {
      final reader = CbzDocumentReader.fromBytes(CbzFixture.build());
      reader.dispose();

      expect(
        () => reader.loadAsset('page1.png'),
        throwsA(isA<DocumentDisposedException>()),
      );
    });
  });
}

Uint8List _zipWithoutImages() {
  final archive = Archive();
  archive.addFile(ArchiveFile.string('readme.txt', 'no images here'));
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}
