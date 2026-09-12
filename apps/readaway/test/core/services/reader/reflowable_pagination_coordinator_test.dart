import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mupdf/mupdf.dart';
import 'package:readaway/src/core/services/reader/reflowable_document_reader.dart';
import 'package:readaway/src/core/services/reader/reflowable_page_slicer.dart';
import 'package:readaway/src/core/services/reader/reflowable_pagination_coordinator.dart';

class _FakeReflowableReader implements ReflowableDocumentReader {
  @override
  final int sectionCount;

  _FakeReflowableReader({this.sectionCount = 5});

  @override
  List<ReflowableSectionItem> get sections => List.generate(
        sectionCount,
        (i) => ReflowableSectionItem(
          index: i,
          id: 'item_$i',
          href: 'chapter_$i.xhtml',
          mediaType: 'application/xhtml+xml',
        ),
      );

  @override
  String? get title => 'Test Book';

  @override
  List<OutlineItem> get outline => const [];

  @override
  String loadSectionHtml(int index) => '<html><body>Chapter $index</body></html>';

  @override
  Uint8List? loadAssetBytes(String assetPath) => null;

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) => relativeHref;

  @override
  int? resolveSectionIndex(String href) => null;

  @override
  void dispose() {}
}

void main() {
  group('ReflowablePageSlicer', () {
    const slicer = ReflowablePageSlicer();

    test('returns single offset for content fitting within viewport', () {
      final offsets = slicer.computePageOffsets(
        contentHeight: 600,
        viewportHeight: 800,
      );
      expect(offsets, equals([0.0]));
    });

    test('slices by viewport height when no line boundaries provided', () {
      final offsets = slicer.computePageOffsets(
        contentHeight: 2500,
        viewportHeight: 1000,
      );
      expect(offsets, equals([0.0, 1000.0, 2000.0]));
    });

    test('snaps cleanly between line boundaries', () {
      // 4 lines: 0-250, 250-500, 500-750, 750-1000, 1000-1250
      final lines = [
        (top: 0.0, bottom: 250.0),
        (top: 250.0, bottom: 500.0),
        (top: 500.0, bottom: 750.0),
        (top: 750.0, bottom: 950.0), // Fits in page 1 (viewport 900) -> Wait: 950 > 900
        (top: 950.0, bottom: 1200.0),
      ];

      final offsets = slicer.computePageOffsets(
        contentHeight: 1200,
        viewportHeight: 900,
        lineBounds: lines,
      );

      // Page 1 covers lines 0..2 (ends at 750, next starts at 750)
      // Page 2 covers line 3 (750..950) and line 4 (950..1200)
      expect(offsets, equals([0.0, 750.0]));
    });
  });

  group('ReflowablePaginationCoordinator', () {
    late ReflowablePaginationCoordinator coordinator;
    late _FakeReflowableReader fakeReader;

    setUp(() {
      coordinator = ReflowablePaginationCoordinator();
      fakeReader = _FakeReflowableReader(sectionCount: 4);
      coordinator.initialize(
        chapterCount: 4,
        reader: fakeReader,
        viewportSize: const Size(400, 800),
        contentMargins: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      );
    });

    test('initializes with 1 page per chapter as initial estimate', () {
      expect(coordinator.chapterCount, equals(4));
      expect(coordinator.totalPageCount, equals(4));

      final coord0 = coordinator.coordinateFromGlobalPage(0);
      expect(coord0.chapterIndex, equals(0));
      expect(coord0.pageInChapter, equals(0));

      final coord3 = coordinator.coordinateFromGlobalPage(3);
      expect(coord3.chapterIndex, equals(3));
      expect(coord3.pageInChapter, equals(0));
    });

    test('updates page counts and prefix sums when chapter heights are registered', () {
      // Chapter 0: 2160px height (availableHeight = 800 - 80 = 720) -> 3 pages
      coordinator.registerChapterHeight(0, 2160);

      // Chapter 1: 1440px -> 2 pages
      coordinator.registerChapterHeight(1, 1440);

      // Total pages: Ch 0 (3) + Ch 1 (2) + Ch 2 (1) + Ch 3 (1) = 7 pages
      expect(coordinator.totalPageCount, equals(7));

      // Global page 0 -> Ch 0, p 0
      expect(coordinator.coordinateFromGlobalPage(0),
          equals(const PageCoordinate(chapterIndex: 0, pageInChapter: 0, totalPagesInChapter: 3, globalPage: 0)));

      // Global page 2 -> Ch 0, p 2
      expect(coordinator.coordinateFromGlobalPage(2),
          equals(const PageCoordinate(chapterIndex: 0, pageInChapter: 2, totalPagesInChapter: 3, globalPage: 2)));

      // Global page 3 -> Ch 1, p 0
      expect(coordinator.coordinateFromGlobalPage(3),
          equals(const PageCoordinate(chapterIndex: 1, pageInChapter: 0, totalPagesInChapter: 2, globalPage: 3)));

      // Global page 4 -> Ch 1, p 1
      expect(coordinator.coordinateFromGlobalPage(4),
          equals(const PageCoordinate(chapterIndex: 1, pageInChapter: 1, totalPagesInChapter: 2, globalPage: 4)));

      // Global page 5 -> Ch 2, p 0
      expect(coordinator.coordinateFromGlobalPage(5),
          equals(const PageCoordinate(chapterIndex: 2, pageInChapter: 0, totalPagesInChapter: 1, globalPage: 5)));
    });

    test('two-way mapping is consistent (coordinate <=> globalPage)', () {
      coordinator.registerChapterHeight(0, 2160); // 3 pages
      coordinator.registerChapterHeight(1, 2880); // 4 pages
      coordinator.registerChapterHeight(2, 720);  // 1 page
      coordinator.registerChapterHeight(3, 1440); // 2 pages
      // Total: 10 pages

      for (int g = 0; g < coordinator.totalPageCount; g++) {
        final coord = coordinator.coordinateFromGlobalPage(g);
        final roundTrip = coordinator.globalPageFromCoordinate(
          coord.chapterIndex,
          coord.pageInChapter,
        );
        expect(roundTrip, equals(g), reason: 'Failed for global page $g');
      }
    });

    test('preserves reading anchor across viewport resize', () {
      coordinator.registerChapterHeight(0, 2880); // 4 pages at height 720
      // User is at global page 2 (Chapter 0, page 2 of 4 -> ~66% progression)
      final anchor = coordinator.createAnchor(2);
      expect(anchor.chapterIndex, equals(0));
      expect(anchor.progressionInChapter, closeTo(2 / 3, 0.01));

      // Resize viewport to taller screen (1000px - 80 = 920px available)
      // 2880 / 920 = 4 pages (ceil) or 3 pages
      final restoredGlobalPage = coordinator.updateViewport(
        viewportSize: const Size(400, 1000),
        contentMargins: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        currentAnchor: anchor,
      );

      final newCoord = coordinator.coordinateFromGlobalPage(restoredGlobalPage);
      expect(newCoord.chapterIndex, equals(0));
      // Progression should still be approximately 66%
      expect(newCoord.progressionInChapter, closeTo(0.66, 0.2));
    });

    test('TOC chapter resolution returns first global page of chapter', () {
      coordinator.registerChapterHeight(0, 2160); // 3 pages (global 0, 1, 2)
      coordinator.registerChapterHeight(1, 1440); // 2 pages (global 3, 4)

      expect(coordinator.getGlobalPageForChapter(0), equals(0));
      expect(coordinator.getGlobalPageForChapter(1), equals(3));
      expect(coordinator.getGlobalPageForChapter(2), equals(5));
    });

    test('initialize and updateViewport respect notify: false', () {
      int notifications = 0;
      coordinator.addListener(() => notifications++);

      coordinator.initialize(
        chapterCount: 4,
        viewportSize: const Size(400, 800),
        contentMargins: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        notify: false,
      );
      expect(notifications, equals(0));

      coordinator.updateViewport(
        viewportSize: const Size(500, 900),
        contentMargins: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        notify: false,
      );
      expect(notifications, equals(0));
    });

    test('registerChapterHeight notifies when offsets change even if page count remains same', () {
      // 1440px -> 2 pages: offsets [0.0, 720.0]
      coordinator.registerChapterHeight(0, 1440);

      int notifications = 0;
      coordinator.addListener(() => notifications++);

      // Register with line bounds: still 2 pages, but snapped offsets [0.0, 700.0]
      final lineBounds = [
        (top: 0.0, bottom: 350.0),
        (top: 350.0, bottom: 700.0),
        (top: 700.0, bottom: 1050.0),
        (top: 1050.0, bottom: 1400.0),
      ];
      coordinator.registerChapterHeight(0, 1440, lineBounds: lineBounds);

      expect(notifications, equals(1));
      expect(coordinator.getChapterPageOffsets(0), equals([0.0, 700.0]));
    });
  });
}
