import 'dart:convert';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('Model JSON round-trips', () {
    test('DocumentSection', () {
      const section = DocumentSection(
        index: 2,
        id: 'ch3',
        href: 'OEBPS/ch3.xhtml',
        mediaType: 'application/xhtml+xml',
        title: 'Chapter Three',
      );
      final json = jsonEncode(section.toJson());
      final decoded = DocumentSection.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, section);
    });

    test('OutlineItem with children', () {
      const item = OutlineItem(
        title: 'Part I',
        href: 'part1.xhtml',
        level: 0,
        children: [OutlineItem(title: 'Section A', href: 'a.xhtml', level: 1)],
      );
      final json = jsonEncode(item.toJson());
      final decoded = OutlineItem.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, item);
      expect(decoded.flatten(), hasLength(2));
    });

    test('DocumentMetadata with DateTime', () {
      const metadata = DocumentMetadata(
        title: 'Book',
        creator: 'Author',
        language: 'en',
        identifier: 'urn:uuid:1',
        publisher: 'Pub',
        description: 'Desc',
        subject: 'Fiction',
        modified: null,
      );
      final json = jsonEncode(metadata.toJson());
      final decoded = DocumentMetadata.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, metadata);
    });

    test('PageCoordinate', () {
      const coord = PageCoordinate(
        chapterIndex: 1,
        pageInChapter: 2,
        totalPagesInChapter: 5,
        globalPage: 7,
      );
      final json = jsonEncode(coord.toJson());
      final decoded = PageCoordinate.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, coord);
      expect(decoded.progressionInChapter, closeTo(0.5, 0.001));
    });

    test('ReadingAnchor', () {
      const anchor = ReadingAnchor(chapterIndex: 3, progressionInChapter: 0.25);
      final json = jsonEncode(anchor.toJson());
      final decoded = ReadingAnchor.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, anchor);
    });

    test('PaginationState with maps', () {
      const state = PaginationState(
        chapterIndex: 1,
        pageInChapter: 2,
        totalPagesInChapter: 4,
        globalPage: 6,
        totalPages: 10,
        viewportHeight: 800,
        chapterHeights: {0: 1600.0, 1: 3200.0},
        chapterPageCounts: {0: 2, 1: 4},
      );
      final json = jsonEncode(state.toJson());
      final decoded = PaginationState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, state);
    });

    test('OpfData', () {
      const opf = OpfData(
        metadata: DocumentMetadata(title: 'Book', creator: 'Author'),
        sections: [
          DocumentSection(
            index: 0,
            id: 'ch1',
            href: 'OEBPS/ch1.xhtml',
            mediaType: 'application/xhtml+xml',
          ),
        ],
        ncxHref: 'toc.ncx',
        navHref: 'nav.xhtml',
        opfDir: 'OEBPS',
      );
      final json = jsonEncode(opf.toJson());
      final decoded = OpfData.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, opf);
    });
  });
}
