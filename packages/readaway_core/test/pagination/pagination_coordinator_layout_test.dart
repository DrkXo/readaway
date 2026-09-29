import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

TextSpanBox _span(int start, int end, double y, {double height = 20}) =>
    TextSpanBox(
      charStart: start,
      charEnd: end,
      rect: Rect.fromLTWH(0, y, 400, height),
      nodeTag: 'p',
      type: 'text',
    );

ChapterTextLayout _layout({
  required List<TextSpanBox> spans,
  required List<PageSlice> pages,
  double contentHeight = 3000,
}) => ChapterTextLayout(
  contentHeight: contentHeight,
  viewportHeight: 1000,
  lineBounds: const [],
  spans: spans,
  pages: pages,
  totalCharacterCount: spans.isEmpty ? 0 : spans.last.charEnd,
  flowText: '',
);

/// Three pages of one chapter: 0-249, 250-499, 500-749.
final ChapterTextLayout _threePages = _layout(
  spans: [_span(0, 250, 0), _span(250, 500, 1000), _span(500, 750, 2000)],
  pages: const [
    PageSlice(index: 0, startY: 0, endY: 1000, startChar: 0, endChar: 250),
    PageSlice(index: 1, startY: 1000, endY: 2000, startChar: 250, endChar: 500),
    PageSlice(index: 2, startY: 2000, endY: 3000, startChar: 500, endChar: 750),
  ],
);

void main() {
  group('registerChapterLayout', () {
    test('exposes the layout and its character mapping', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );

      expect(coordinator.hasCharacterMapping(0), isFalse);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      expect(coordinator.hasCharacterMapping(0), isTrue);
      expect(coordinator.getChapterLayout(0), isNotNull);
      expect(coordinator.pageForChar(0, 250), 1);
      expect(coordinator.pageForChar(0, 500), 2);
    });

    test('an unavailable layout reports no character mapping', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );

      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: ChapterTextLayout.unavailable(
          contentHeight: 3000,
          viewportHeight: 1000,
          lineBounds: const [],
        ),
      );

      expect(coordinator.hasCharacterMapping(0), isFalse);
      expect(coordinator.pageForChar(0, 250), 0);
      expect(coordinator.charForPage(0, 1), isNull);
      expect(coordinator.rectsForCharRange(0, 0, 100), isEmpty);
    });

    test('adopts the layout height for page counting', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      expect(coordinator.getChapterHeight(0), 3000);
      expect(coordinator.currentState.totalPages, 3);
    });
  });

  group('character mapping invalidation', () {
    test('a height change drops the mapping', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);
      expect(coordinator.hasCharacterMapping(0), isTrue);

      coordinator.registerChapterHeight(chapterIndex: 0, contentHeight: 2500);

      expect(coordinator.hasCharacterMapping(0), isFalse);
      expect(coordinator.getChapterLayout(0), isNull);
    });

    test('invalidate drops the mapping', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      coordinator.invalidate();

      expect(coordinator.hasCharacterMapping(0), isFalse);
      expect(coordinator.getChapterLayout(0), isNull);
    });

    test('reset drops the mapping', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      coordinator.reset();

      expect(coordinator.hasCharacterMapping(0), isFalse);
      expect(coordinator.getChapterLayout(0), isNull);
    });

    test(
      're-registering identical geometry keeps the same layout instance',
      () {
        final coordinator = PaginationCoordinator();
        coordinator.initialize(
          chapterCount: 1,
          viewportHeight: 1000,
          contentHeight: 3000,
        );
        coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);
        final first = coordinator.getChapterLayout(0);

        coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

        expect(identical(coordinator.getChapterLayout(0), first), isTrue);
      },
    );
  });

  group('pageForChar', () {
    test('maps offsets onto the containing page', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      expect(coordinator.pageForChar(0, 0), 0);
      expect(coordinator.pageForChar(0, 249), 0);
      expect(coordinator.pageForChar(0, 250), 1);
      expect(coordinator.pageForChar(0, 500), 2);
    });

    test('clamps offsets past the end of the chapter', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      expect(coordinator.pageForChar(0, 99999), 2);
    });

    test('returns 0 for an unmeasured chapter', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 3,
        viewportHeight: 1000,
        contentHeight: 3000,
      );

      expect(coordinator.pageForChar(2, 500), 0);
    });
  });

  group('globalPageForChar', () {
    test('offsets by the pages of preceding chapters', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 2,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      // Chapter 0 measures three pages, so chapter 1 starts at global page 3.
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);
      coordinator.registerChapterLayout(chapterIndex: 1, layout: _threePages);

      expect(coordinator.getGlobalPageForChapter(1), 3);
      expect(coordinator.globalPageForChar(1, 250), 4);
      expect(coordinator.globalPageForChar(0, 250), 1);
    });
  });

  group('charForPage', () {
    test('round-trips with pageForChar', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      for (var page = 0; page < 3; page++) {
        final char = coordinator.charForPage(0, page);
        expect(char, isNotNull);
        expect(coordinator.pageForChar(0, char!), page);
      }
    });
  });

  group('rectsForCharRange', () {
    test('returns the boxes covering the range', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _threePages);

      final rects = coordinator.rectsForCharRange(0, 200, 300);
      expect(rects.length, 2);
      expect(rects[0].top, 0);
      expect(rects[1].top, 1000);
    });
  });
}
