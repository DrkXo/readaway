import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

TextSpanBox _span(int start, int end, double y) => TextSpanBox(
  charStart: start,
  charEnd: end,
  rect: Rect.fromLTWH(0, y, 300, 16),
  nodeTag: 'p',
  type: 'text',
);

ChapterTextLayout _layout({
  required List<TextSpanBox> spans,
  required List<TextBlock> blocks,
  required List<PageSlice> pages,
  int totalCharacterCount = 1000,
  String flowText = '',
}) => ChapterTextLayout(
  contentHeight: 2000,
  viewportHeight: 800,
  lineBounds: const [],
  spans: spans,
  blocks: blocks,
  pages: pages,
  totalCharacterCount: totalCharacterCount,
  flowText: flowText,
);

PageSlice _page(int i, double y, int c) => PageSlice(
  index: i,
  startY: y,
  endY: y + 800,
  startChar: c,
  endChar: c + 250,
);

void main() {
  group('ChapterTextLayout.pageForChar', () {
    final layout = _layout(
      spans: [_span(0, 250, 0), _span(250, 500, 800), _span(500, 750, 1600)],
      blocks: const [],
      pages: [_page(0, 0, 0), _page(1, 800, 250), _page(2, 1600, 500)],
    );

    test('maps a char offset to the page that contains it', () {
      expect(layout.pageForChar(0), 0);
      expect(layout.pageForChar(249), 0);
      expect(layout.pageForChar(250), 1);
      expect(layout.pageForChar(499), 1);
      expect(layout.pageForChar(500), 2);
    });

    test('clamps offsets outside the chapter', () {
      expect(layout.pageForChar(-40), 0);
      expect(layout.pageForChar(99999), 2);
    });

    test('returns 0 when no character mapping is available', () {
      final unavailable = ChapterTextLayout.unavailable(
        contentHeight: 2000,
        viewportHeight: 800,
        lineBounds: const [],
      );
      expect(unavailable.hasCharacterMapping, isFalse);
      expect(unavailable.pageForChar(500), 0);
    });
  });

  group('ChapterTextLayout.charForPage', () {
    test('round-trips with pageForChar at every boundary', () {
      final layout = _layout(
        spans: const [],
        blocks: const [],
        pages: [_page(0, 0, 0), _page(1, 800, 250), _page(2, 1600, 500)],
      );
      for (var i = 0; i < layout.pages.length; i++) {
        final char = layout.charForPage(i)!;
        expect(layout.pageForChar(char), i);
      }
    });

    test('returns null for out-of-range pages', () {
      final layout = _layout(
        spans: const [],
        blocks: const [],
        pages: [_page(0, 0, 0)],
      );
      expect(layout.charForPage(-1), isNull);
      expect(layout.charForPage(1), isNull);
    });
  });

  group('ChapterTextLayout.rectsForCharRange', () {
    final layout = _layout(
      spans: [_span(0, 250, 0), _span(250, 500, 800), _span(500, 750, 1600)],
      blocks: const [],
      pages: const [],
    );

    test('returns every span the range touches', () {
      final rects = layout.rectsForCharRange(200, 300);
      expect(rects.length, 2);
      expect(rects[0].top, 0);
      expect(rects[1].top, 800);
    });

    test('treats ranges as half-open', () {
      // [200, 250) touches only the first span.
      expect(layout.rectsForCharRange(200, 250).length, 1);
      // [500, 500) is empty.
      expect(layout.rectsForCharRange(500, 500), isEmpty);
      expect(layout.rectsForCharRange(600, 500), isEmpty);
    });

    test('a range inside one span yields exactly that span', () {
      final rects = layout.rectsForCharRange(300, 400);
      expect(rects.length, 1);
      expect(rects.single.top, 800);
    });
  });

  group('ChapterTextLayout.matches', () {
    test('equal geometry matches', () {
      final a = _layout(
        spans: const [],
        blocks: const [],
        pages: [_page(0, 0, 0), _page(1, 800, 250)],
      );
      final b = _layout(
        spans: const [],
        blocks: const [],
        pages: [_page(0, 0, 0), _page(1, 800, 250)],
      );
      expect(a.matches(b), isTrue);
      expect(b.matches(a), isTrue);
    });

    test('a changed char offset is a change', () {
      final a = _layout(
        spans: const [],
        blocks: const [],
        pages: [_page(0, 0, 0), _page(1, 800, 250)],
      );
      final b = _layout(
        spans: const [],
        blocks: const [],
        pages: [_page(0, 0, 0), _page(1, 800, 251)],
      );
      expect(a.matches(b), isFalse);
    });

    test('a changed character count is a change', () {
      final a = _layout(
        spans: const [],
        blocks: const [],
        pages: const [],
        totalCharacterCount: 100,
      );
      final b = _layout(
        spans: const [],
        blocks: const [],
        pages: const [],
        totalCharacterCount: 101,
      );
      expect(a.matches(b), isFalse);
    });

    test('a changed flow text is a change even at identical geometry', () {
      // An element can render as a list marker at one width and as plain text
      // at another, leaving the character count and pagination untouched while
      // changing which character sits at which offset. Anything built against
      // the old text would then be silently wrong.
      final geometry = (
        spans: const <TextSpanBox>[],
        blocks: const <TextBlock>[],
        pages: [_page(0, 0, 0), _page(1, 800, 250)],
      );
      final withMarker = _layout(
        spans: geometry.spans,
        blocks: geometry.blocks,
        pages: geometry.pages,
        flowText: '1. Alpha Beta',
      );
      final withoutMarker = _layout(
        spans: geometry.spans,
        blocks: geometry.blocks,
        pages: geometry.pages,
        flowText: 'Alpha Beta',
      );

      expect(withMarker.matches(withoutMarker), isFalse);
      expect(withoutMarker.matches(withMarker), isFalse);
    });
  });

  group('ChapterTextLayout.unavailable', () {
    test('reports no character mapping', () {
      final layout = ChapterTextLayout.unavailable(
        contentHeight: 500,
        viewportHeight: 800,
        lineBounds: const [],
      );
      expect(layout.hasCharacterMapping, isFalse);
      expect(layout.spans, isEmpty);
      expect(layout.blocks, isEmpty);
      expect(layout.pages, isEmpty);
      expect(layout.rectsForCharRange(0, 100), isEmpty);
    });
  });
}
