import 'dart:convert';
import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

import '../fixtures/epub_fixture.dart';

void main() {
  group('OpfParser', () {
    late EpubContainer container;
    late OpfParser parser;

    setUp(() {
      container = EpubContainer.openBytes(EpubFixture.build());
      parser = const OpfParser();
    });

    tearDown(() => container.dispose());

    test('finds the OPF path from container.xml', () {
      expect(parser.findOpfPath(container), 'OEBPS/content.opf');
    });

    test('parses metadata', () {
      final opf = parser.parse(container, opfPath: 'OEBPS/content.opf');

      expect(opf.metadata.title, 'Test Book');
      expect(opf.metadata.creator, 'Test Author');
      expect(opf.metadata.language, 'en');
      expect(opf.metadata.publisher, 'Test Publisher');
      expect(opf.metadata.identifier, 'urn:uuid:test-book');
      expect(opf.metadata.modified, DateTime.utc(2024, 1, 1));
    });

    test('parses spine sections with hrefs resolved to the OPF dir', () {
      final opf = parser.parse(container, opfPath: 'OEBPS/content.opf');

      expect(opf.sections, hasLength(2));
      expect(opf.sections[0].index, 0);
      expect(opf.sections[0].id, 'chapter1');
      expect(opf.sections[0].href, 'OEBPS/chapter1.xhtml');
      expect(opf.sections[0].mediaType, 'application/xhtml+xml');
      expect(opf.sections[1].href, 'OEBPS/chapter2.xhtml');
    });

    test('detects NCX and nav manifest items', () {
      final opf = parser.parse(container, opfPath: 'OEBPS/content.opf');

      expect(opf.ncxHref, 'toc.ncx');
      expect(opf.navHref, 'nav.xhtml');
      expect(opf.opfDir, 'OEBPS');
    });

    test('detects the cover image from manifest properties', () {
      final opf = parser.parse(container, opfPath: 'OEBPS/content.opf');

      expect(opf.coverImagePath, 'OEBPS/images/cover.png');
    });

    test('returns null cover when none is declared', () {
      final noCover = EpubContainer.openBytes(
        EpubFixture.build(includeCover: false),
      );
      final opf = parser.parse(noCover, opfPath: 'OEBPS/content.opf');
      expect(opf.coverImagePath, isNull);
      noCover.dispose();
    });

    test('throws DocumentParseException when the OPF is missing', () {
      expect(
        () => parser.parse(container, opfPath: 'missing.opf'),
        throwsA(isA<DocumentParseException>()),
      );
    });
  });

  group('OpfParser bytes-based entry points', () {
    test('findOpfPathFromBytes returns null for empty/malformed bytes', () {
      expect(const OpfParser().findOpfPathFromBytes(null), isNull);
      expect(const OpfParser().findOpfPathFromBytes(Uint8List(0)), isNull);
      expect(
        const OpfParser().findOpfPathFromBytes(utf8.encode('not xml')),
        isNull,
      );
    });

    test('findOpfPathFromBytes locates the OPF from raw container.xml', () {
      final container = EpubContainer.openBytes(EpubFixture.build());
      final bytes = container.readEntry('META-INF/container.xml');
      container.dispose();

      expect(
        const OpfParser().findOpfPathFromBytes(bytes),
        'OEBPS/content.opf',
      );
    });

    test('parseBytes parses raw OPF bytes', () {
      final container = EpubContainer.openBytes(EpubFixture.build());
      final bytes = container.readEntry('OEBPS/content.opf');
      container.dispose();

      final opf = const OpfParser().parseBytes(bytes!, opfDir: 'OEBPS');
      expect(opf.metadata.title, 'Test Book');
      expect(opf.sections, hasLength(2));
      expect(opf.sections[0].href, 'OEBPS/chapter1.xhtml');
      expect(opf.ncxHref, 'toc.ncx');
      expect(opf.navHref, 'nav.xhtml');
    });

    test('findFallbackOpf finds conventional OPF paths', () {
      final container = EpubContainer.openBytes(EpubFixture.build());
      expect(const OpfParser().findFallbackOpf(container), 'OEBPS/content.opf');
      container.dispose();
    });
  });
}
