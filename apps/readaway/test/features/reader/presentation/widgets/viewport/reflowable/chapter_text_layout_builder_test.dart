import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/chapter_text_layout_builder.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('ChapterTextLayoutBuilder._buildPages', () {
    test('a single page spans the whole chapter', () {
      final pages = _pagesFor(
        offsets: const [0.0],
        spans: [
          _span(0, 100, 0),
          _span(100, 200, 20),
        ],
        contentHeight: 500,
        totalCharacters: 200,
      );

      expect(pages.length, 1);
      expect(pages.single.index, 0);
      expect(pages.single.startChar, 0);
      expect(pages.single.endChar, 200);
      expect(pages.single.endY, 500);
    });

    test('splits pages at the last span above each break', () {
      // Three spans of 20px at y=0, 1000, 2000 with breaks at 0/1000/2000.
      // The span at y=1000 starts exactly at the break, so page 1 starts there.
      final pages = _pagesFor(
        offsets: const [0.0, 1000.0, 2000.0],
        spans: [
          _span(0, 100, 0),
          _span(100, 200, 1000),
          _span(200, 300, 2000),
        ],
        contentHeight: 3000,
        totalCharacters: 300,
      );

      expect(pages.length, 3);
      expect(pages[0].startChar, 0);
      expect(pages[1].startChar, 100);
      expect(pages[2].startChar, 200);
      // endChar of each page equals the next page's startChar.
      expect(pages[0].endChar, 100);
      expect(pages[1].endChar, 200);
      expect(pages[2].endChar, 300);
    });

    test('a break mid-span starts the page at that span', () {
      // Break at 1010 falls inside the span occupying y=1000..1020, so the
      // page must begin at that span's start rather than at a guessed offset.
      final pages = _pagesFor(
        offsets: const [0.0, 1010.0],
        spans: [
          _span(0, 100, 0),
          _span(100, 200, 1000),
          _span(200, 300, 1020),
        ],
        contentHeight: 2000,
        totalCharacters: 300,
      );

      expect(pages.length, 2);
      expect(pages[1].startChar, 100);
    });

    test('the last page ends at the chapter total', () {
      final pages = _pagesFor(
        offsets: const [0.0, 1000.0],
        spans: [
          _span(0, 100, 0),
          _span(100, 150, 1000),
        ],
        contentHeight: 2000,
        totalCharacters: 150,
      );

      expect(pages.last.endChar, 150);
    });

    test('a break past the last span starts at the chapter total', () {
      // A trailing image pushes the final page break below all text, so that
      // page legitimately contains no characters.
      final pages = _pagesFor(
        offsets: const [0.0, 5000.0],
        spans: [_span(0, 100, 0)],
        contentHeight: 6000,
        totalCharacters: 100,
      );

      expect(pages.length, 2);
      expect(pages[1].startChar, 100);
      expect(pages[1].endChar, 100);
    });

    test('startChar values are non-decreasing', () {
      final pages = _pagesFor(
        offsets: const [0.0, 500.0, 1000.0, 1500.0],
        spans: [
          _span(0, 50, 0),
          _span(50, 100, 400),
          _span(100, 150, 900),
          _span(150, 200, 1400),
        ],
        contentHeight: 2000,
        totalCharacters: 200,
      );

      for (var i = 1; i < pages.length; i++) {
        expect(
          pages[i].startChar,
          greaterThanOrEqualTo(pages[i - 1].startChar),
        );
      }
    });
  });

  group('ChapterTextLayoutBuilder.buildFromFragments accounting', () {
    ChapterTextLayout build({
      required List<LayoutFragment> fragments,
      required int totalCharacterCount,
      double contentHeight = 500,
      double viewportHeight = 1000,
    }) => const ChapterTextLayoutBuilder().buildFromFragments(
      fragments: fragments,
      lineBounds: null,
      totalCharacterCount: totalCharacterCount,
      contentHeight: contentHeight,
      viewportHeight: viewportHeight,
    );

    test('rejects a layout whose character total disagrees', () {
      // The render object reports 999 characters but the fragments sum to 10.
      // That means the upstream accounting rule changed, so the builder must
      // refuse to emit a mapping rather than emit wrong offsets. Debug builds
      // also assert, which is how this surfaces during development.
      expect(
        () => build(
          fragments: [
            LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'p', 0, 20)),
            LayoutFragment.fromDebugMap(_frag('text', 'World', 'p', 0, 20)),
          ],
          totalCharacterCount: 999,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a rejected layout carries no character mapping', () {
      // The release-mode contract: once the mismatch check fails, callers get
      // an unavailable layout whose page lookups are all safe no-ops.
      final layout = const ChapterTextLayoutBuilder().buildFromFragments(
        fragments: [
          LayoutFragment(type: 'text', text: 'Hello', nodeTag: 'p'),
        ],
        lineBounds: null,
        totalCharacterCount: 999,
        contentHeight: 500,
        viewportHeight: 1000,
        // Bypass the debug assertion to observe the fallback value itself.
        suppressCharacterTotalAssertion: true,
      );

      expect(layout.hasCharacterMapping, isFalse);
      expect(layout.spans, isEmpty);
      expect(layout.pages, isEmpty);
      expect(layout.pageForChar(500), 0);
    });

    test('accepts fragments that reconcile with the reported total', () {
      final layout = build(
        fragments: [
          LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'p', 0, 20)),
          LayoutFragment.fromDebugMap(_frag('text', 'World', 'p', 0, 20)),
        ],
        totalCharacterCount: 10,
      );

      expect(layout.hasCharacterMapping, isTrue);
      expect(layout.totalCharacterCount, 10);
      expect(layout.pageForChar(0), 0);
      expect(layout.pageForChar(10), 0);
    });

    test('empty fragments yield an unavailable layout', () {
      final layout = build(fragments: const [], totalCharacterCount: 0);
      expect(layout.hasCharacterMapping, isFalse);
    });

    test('assigns ascending character offsets across fragments', () {
      final layout = build(
        fragments: [
          LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'p', 0, 20)),
          LayoutFragment.fromDebugMap(_frag('text', 'World', 'p', 20, 20)),
          LayoutFragment.fromDebugMap(_frag('text', 'Again', 'p', 40, 20)),
        ],
        totalCharacterCount: 15,
      );

      final starts = layout.spans.map((s) => s.charStart).toList();
      final ends = layout.spans.map((s) => s.charEnd).toList();
      expect(starts, [0, 5, 10]);
      expect(ends, [5, 10, 15]);
    });

    test('block boundaries do not consume characters', () {
      // A block-start/end fragment is reported as type 'text' with empty
      // text, exactly like an inline boundary, so it must not shift offsets.
      final layout = build(
        fragments: [
          LayoutFragment.fromDebugMap(_frag('text', '', 'p', 0, 0)),
          LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'span', 0, 20)),
          LayoutFragment.fromDebugMap(_frag('text', '', 'p', 20, 0)),
        ],
        totalCharacterCount: 5,
      );

      expect(layout.spans.single.charStart, 0);
      expect(layout.spans.single.charEnd, 5);
      expect(layout.blocks.single.tag, 'p');
    });

    test('a line break consumes exactly one character', () {
      final layout = build(
        fragments: [
          LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'p', 0, 20)),
          LayoutFragment.fromDebugMap(_frag('lineBreak', '\n', 'br', 20, 0)),
          LayoutFragment.fromDebugMap(_frag('text', 'World', 'p', 40, 20)),
        ],
        totalCharacterCount: 11,
      );

      expect(layout.spans.map((s) => s.charStart), [0, 6]);
      expect(layout.spans.map((s) => s.charEnd), [5, 11]);
      // The break closes the first block, so two blocks are produced.
      expect(layout.blocks.length, 2);
    });

    test('an atomic fragment consumes no characters', () {
      final layout = build(
        fragments: [
          LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'p', 0, 20)),
          LayoutFragment.fromDebugMap(
            _frag('atomic', 'ignored', 'img', 20, 100),
          ),
          LayoutFragment.fromDebugMap(_frag('text', 'World', 'p', 120, 20)),
        ],
        totalCharacterCount: 10,
      );

      // The image has non-empty text but is not flow text, so it contributes
      // nothing to the accounting and gets no span.
      expect(layout.spans.length, 2);
      expect(layout.spans.last.charStart, 5);
    });

    test('materialises the flow text that the offsets index', () {
      final layout = build(
        fragments: [
          LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'p', 0, 20)),
          LayoutFragment.fromDebugMap(_frag('lineBreak', '\n', 'br', 20, 0)),
          LayoutFragment.fromDebugMap(_frag('text', 'World', 'p', 40, 20)),
        ],
        totalCharacterCount: 11,
      );

      // The rendered flow text is what selection copies, so a span's
      // [charStart]..[charEnd] must slice exactly its own characters out of
      // it. This is the invariant the speech map is built against.
      expect(layout.flowText, 'Hello\nWorld');
      expect(layout.flowText.length, layout.totalCharacterCount);
      expect(
        layout.flowText.substring(
          layout.spans[0].charStart,
          layout.spans[0].charEnd,
        ),
        'Hello',
      );
      expect(
        layout.flowText.substring(
          layout.spans[1].charStart,
          layout.spans[1].charEnd,
        ),
        'World',
      );
    });

    test('an unavailable layout carries no flow text', () {
      final layout = build(fragments: const [], totalCharacterCount: 0);

      expect(layout.flowText, isEmpty);
      expect(layout.hasCharacterMapping, isFalse);
    });

    test('unmeasured fragments still advance the character cursor', () {
      // A fragment with characters but null geometry must count toward the
      // total, or the reconciliation would reject valid layouts.
      final layout = build(
        fragments: [
          LayoutFragment.fromDebugMap(_frag('text', 'Hello', 'p', 0, 20)),
          LayoutFragment(text: 'World', type: 'text', nodeTag: 'p'),
        ],
        totalCharacterCount: 10,
      );

      expect(layout.hasCharacterMapping, isTrue);
      expect(layout.spans.length, 1);
      expect(layout.blocks.single.charEnd, 10);
    });
  });
}

TextSpanBox _span(int start, int end, double y) => TextSpanBox(
  charStart: start,
  charEnd: end,
  rect: Rect.fromLTWH(0, y, 400, 20),
  nodeTag: 'p',
  type: 'text',
);

Map<String, dynamic> _frag(
  String type,
  String text,
  String tag,
  double y,
  double height,
) => {
  'type': type,
  'text': text,
  'offsetX': 0.0,
  'offsetY': y,
  'width': 400.0,
  'height': height,
  'nodeTag': tag,
};

/// Exercises the page-building helper, which is static on the builder.
List<PageSlice> _pagesFor({
  required List<double> offsets,
  required List<TextSpanBox> spans,
  required double contentHeight,
  required int totalCharacters,
}) => ChapterTextLayoutBuilder.buildPages(
  offsets,
  spans,
  contentHeight,
  totalCharacters,
);
