import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

import '../fixtures/epub_fixture.dart';

void main() {
  group('EpubDocumentReader', () {
    late EpubDocumentReader reader;

    setUp(() async {
      reader = await EpubDocumentReader.fromBytes(EpubFixture.build());
    });

    tearDown(() => reader.dispose());

    test('exposes format and reflowable flags', () {
      expect(reader.format, 'epub');
      expect(reader.isReflowable, isTrue);
    });

    test('exposes title and metadata', () {
      expect(reader.title, 'Test Book');
      expect(reader.metadata, isNotNull);
      expect(reader.metadata!.creator, 'Test Author');
      expect(reader.metadata!.language, 'en');
    });

    test('exposes spine sections', () {
      expect(reader.sectionCount, 2);
      expect(reader.sections, hasLength(2));
      expect(reader.sections[0].href, 'OEBPS/chapter1.xhtml');
      expect(reader.sections[1].href, 'OEBPS/chapter2.xhtml');
    });

    test('builds outline from NCX', () {
      expect(reader.outline, hasLength(2));
      expect(reader.outline[0].title, 'Chapter 1');
      expect(reader.outline[0].href, 'OEBPS/chapter1.xhtml');
      expect(reader.outline[1].title, 'Chapter 2');
    });

    test('populates chapterIndex on outline items', () {
      expect(reader.outline[0].chapterIndex, 0);
      expect(reader.outline[1].chapterIndex, 1);
    });

    test('exposes the cover image path', () {
      expect(reader.coverImagePath, 'OEBPS/images/cover.png');
    });

    test('loads section HTML', () {
      final html = reader.loadSectionHtml(0);
      expect(html, contains('Chapter 1'));
      expect(html, contains('<h1>'));
    });

    test('throws RangeError for out-of-range sections', () {
      expect(() => reader.loadSectionHtml(99), throwsRangeError);
    });

    test('loads embedded assets', () {
      final asset = reader.loadAsset('OEBPS/images/cover.png');
      expect(asset, isNotNull);
      expect(asset, equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(reader.loadAsset('missing.png'), isNull);
    });

    test('resolves asset paths relative to the section', () {
      expect(
        reader.resolveAssetPath(0, 'images/cover.png'),
        'OEBPS/images/cover.png',
      );
      // From OEBPS/chapter2.xhtml, ../images/cover.png climbs out of OEBPS.
      expect(
        reader.resolveAssetPath(1, '../images/cover.png'),
        'images/cover.png',
      );
    });

    test('resolves section indices from hrefs', () {
      expect(reader.resolveSectionIndex('OEBPS/chapter2.xhtml'), 1);
      expect(reader.resolveSectionIndex('chapter2.xhtml'), 1);
      expect(reader.resolveSectionIndex('chapter2.xhtml#frag'), 1);
      expect(reader.resolveSectionIndex('unknown.xhtml'), isNull);
    });

    test('throws DocumentDisposedException after dispose', () {
      reader.dispose();
      expect(
        () => reader.loadSectionHtml(0),
        throwsA(isA<DocumentDisposedException>()),
      );
      expect(
        () => reader.loadAsset('OEBPS/images/cover.png'),
        throwsA(isA<DocumentDisposedException>()),
      );
    });
  });

  group('EpubDocumentReader outline fallback', () {
    test('falls back to flat per-section outline without NCX/nav', () async {
      final reader = await EpubDocumentReader.fromBytes(
        EpubFixture.build(includeNcx: false, includeNav: false),
      );

      expect(reader.outline, hasLength(2));
      expect(reader.outline[0].title, 'Chapter 1');
      expect(reader.outline[0].href, 'OEBPS/chapter1.xhtml');
      expect(reader.outline[0].chapterIndex, 0);
      expect(reader.outline[1].chapterIndex, 1);

      reader.dispose();
    });
  });
}
