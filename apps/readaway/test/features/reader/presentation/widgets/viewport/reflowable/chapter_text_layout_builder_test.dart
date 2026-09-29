import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/chapter_text_layout_builder.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('ChapterTextLayoutBuilder.buildPages', () {
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

  // The tokenizer fragments and the line fragments answer different questions.
  // The tokenizer is the only complete account of the chapter's character space
  // — it includes text that never reaches a line — so it reconstructs the flow
  // text and reconciles the total. The lines are the only account of where
  // anything was painted, so they produce the spans. The groups below are split
  // along that line deliberately: mixing the two is the defect this work fixed.
  group('flow text is reconstructed from the tokenizer fragments', () {
    test('rejects a layout whose character total disagrees', () {
      // The render object reports 999 characters but the fragments sum to 10.
      // That means the upstream accounting rule changed, so the builder must
      // refuse to emit a mapping rather than emit wrong offsets. Debug builds
      // also assert, which is how this surfaces during development.
      expect(
        () => build(fragments: [_text('Hello'), _text('World')], total: 999),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a rejected layout carries no character mapping', () {
      // The release-mode contract: once the mismatch check fails, callers get
      // an unavailable layout whose page lookups are all safe no-ops.
      final layout = build(
        fragments: [_text('Hello')],
        total: 999,
        suppress: true,
      );

      expect(layout.hasCharacterMapping, isFalse);
      expect(layout.spans, isEmpty);
      expect(layout.pages, isEmpty);
      expect(layout.pageForChar(500), 0);
    });

    test('empty fragments yield an unavailable layout', () {
      final layout = build(fragments: const [], total: 0);
      expect(layout.hasCharacterMapping, isFalse);
      expect(layout.flowText, isEmpty);
    });

    test('a line break consumes exactly one character', () {
      final layout = build(
        fragments: [
          _text('Hello'),
          const LayoutFragment(type: 'lineBreak', text: '\n', nodeTag: 'br'),
          _text('World'),
        ],
        total: 11,
      );

      expect(layout.flowText, 'Hello\nWorld');
      expect(layout.flowText.length, layout.totalCharacterCount);
    });

    test('an atomic fragment consumes no characters', () {
      // The image has non-empty text but is not flow text, so it contributes
      // nothing to the accounting and gets no span.
      final layout = build(
        fragments: [
          _text('Hello'),
          const LayoutFragment(type: 'atomic', text: 'ignored', nodeTag: 'img'),
          _text('World'),
        ],
        total: 10,
      );

      expect(layout.flowText, 'HelloWorld');
    });

    test('block boundaries do not consume characters', () {
      // A block-start/end fragment is reported as type 'text' with empty
      // text, exactly like an inline boundary, so it must not shift offsets.
      final layout = build(
        fragments: [
          const LayoutFragment(type: 'text', text: '', nodeTag: 'p'),
          _text('Hello'),
          const LayoutFragment(type: 'text', text: '', nodeTag: 'p'),
        ],
        total: 5,
      );

      expect(layout.flowText, 'Hello');
    });

    test('unmeasured fragments still advance the character cursor', () {
      // This is why the tokenizer walk survives at all. A text fragment with no
      // geometry is exactly the wrapped-paragraph case — it was laid out and
      // painted, but the tokenizer reports it unpositioned — and it still counts
      // toward the total, or the reconciliation would reject every chapter of
      // ordinary prose.
      final layout = build(
        fragments: [_text('Hello'), _text('World')],
        total: 10,
      );

      expect(layout.flowText, 'HelloWorld');
      expect(layout.totalCharacterCount, 10);
    });
  });

  group('spans come from the positioned line fragments', () {
    test('a wrapped paragraph yields one span per line', () {
      // The defect this work fixed: with spans derived from the tokenizer, a
      // wrapped paragraph produced no spans at all, because the tokenizer's
      // single unpositioned fragment for it was skipped. One span per line is
      // what makes a sentence resolve to the runs of glyphs it covers.
      const text = 'The quick brown fox jumps. It was late.';
      final layout = build(
        fragments: [_text(text)],
        total: text.length,
        lineFragments: _lines(const [
          'The quick brown',
          ' fox jumps.',
          ' It was',
          ' late.',
        ]),
      );

      expect(layout.spans.length, 4);
      expect(layout.hasCharacterMapping, isTrue);
    });

    test('offsets are the renderer\'s, not re-derived by prefix sum', () {
      // The point of the change. These offsets are deliberately not what a walk
      // over the tokenizer would produce, and the builder must pass them
      // through unchanged rather than recomputing them.
      const text = 'Hello World';
      final layout = build(
        fragments: [_text(text)],
        total: text.length,
        lineFragments: [
          _line('Hello', charStart: 0, y: 0, lineIndex: 0),
          _line('World', charStart: 6, y: 20, lineIndex: 1),
        ],
      );

      expect(
        layout.spans.map((s) => (s.charStart, s.charEnd)),
        [(0, 5), (6, 11)],
        reason:
            'index 5 is the space trimmed at the wrap and belongs to no '
            'fragment, so the second range must start at 6',
      );
    });

    test('a sentence spanning a wrap resolves to the runs it covers', () {
      // The user-visible goal. A sentence crossing a line break used to be
      // either unhighlightable or smeared across the whole paragraph; here it
      // resolves to the two fragments that actually hold its glyphs.
      const text = 'The quick brown fox jumps. It was late.';
      final first = 'The quick brown fox jumps.';
      final second = 'It was late.';
      final layout = build(
        fragments: [_text(text)],
        total: text.length,
        lineFragments: _lines(const [
          'The quick brown',
          ' fox jumps.',
          ' It was',
          ' late.',
        ]),
      );

      final firstRects = layout.rectsForCharRange(
        text.indexOf(first),
        text.indexOf(first) + first.length,
      );
      final secondRects = layout.rectsForCharRange(
        text.indexOf(second),
        text.indexOf(second) + second.length,
      );

      expect(
        firstRects.length,
        2,
        reason: 'the first sentence straddles lines 0 and 1',
      );
      expect(
        secondRects.length,
        2,
        reason: 'the second straddles lines 2 and 3',
      );
      expect(
        firstRects.map((r) => r.top),
        [0.0, 20.0],
        reason: 'distinct lines, not one rect covering both',
      );
      expect(
        secondRects.map((r) => r.top),
        [40.0, 60.0],
      );
    });

    test('a range landing in a wrap gap has no rect', () {
      // Whitespace trimmed at a wrap belongs to no fragment, so highlighting it
      // correctly produces nothing rather than smearing into a neighbour.
      const text = 'Hello World';
      final layout = build(
        fragments: [_text(text)],
        total: text.length,
        lineFragments: [
          _line('Hello', charStart: 0, y: 0, lineIndex: 0),
          _line('World', charStart: 6, y: 20, lineIndex: 1),
        ],
      );

      expect(layout.rectsForCharRange(5, 6), isEmpty);
    });

    test('a truncated fragment is not highlighted past the clamp', () {
      // Only ellipsisVisibleLength characters reached the screen, so the rest
      // must not be painted as though it were visible.
      const text = 'Supercalifragilistic';
      final visible = 6;
      final layout = build(
        fragments: [_text(text)],
        total: text.length,
        lineFragments: [
          _line(
            text,
            charStart: 0,
            y: 0,
            lineIndex: 0,
            ellipsisVisibleLength: visible,
          ),
        ],
      );

      expect(layout.spans.single.charStart, 0);
      expect(layout.spans.single.charEnd, visible);
      expect(layout.rectsForCharRange(visible, text.length), isEmpty);
    });
  });

  group('page assignment', () {
    // The property that makes `pageForChar`'s binary search well-founded. With
    // no spans, every page claimed to start at the chapter total, so the search
    // collapsed to page 0 for the whole chapter and the only thing preventing a
    // visibly wrong page was `hasCharacterMapping` three layers upstream.
    test('each page round-trips through pageForChar', () {
      const lines = 25;
      final pieces = [
        for (var i = 0; i < lines; i++) 'line$i ',
      ];
      final layout = build(
        fragments: [_text(pieces.join())],
        total: pieces.join().length,
        lineFragments: _lines(pieces),
        contentHeight: 500,
        viewportHeight: 100,
      );

      expect(layout.pages.length, 5);
      expect(
        layout.pageStartChars.toSet().length,
        layout.pages.length,
        reason: 'pages must claim distinct starts, or the search is degenerate',
      );
      for (var i = 0; i < layout.pages.length; i++) {
        expect(
          layout.pageForChar(layout.pages[i].startChar),
          i,
          reason: 'page $i must resolve to itself',
        );
      }
    });

    test('the last character resolves to the last page', () {
      final pieces = [for (var i = 0; i < 25; i++) 'line$i '];
      final layout = build(
        fragments: [_text(pieces.join())],
        total: pieces.join().length,
        lineFragments: _lines(pieces),
        contentHeight: 500,
        viewportHeight: 100,
      );

      expect(
        layout.pageForChar(layout.totalCharacterCount - 1),
        layout.pages.length - 1,
      );
    });
  });

  group('line fragment offsets are cross-checked against the flow text', () {
    // The tripwire for a bad merge of the fork. A change in how the renderer
    // derives globalOffset would surface here as a refusal to build a mapping,
    // rather than as a highlight in the wrong place.
    test('rejects a fragment whose text does not match at its offset', () {
      expect(
        () => build(
          fragments: [_text('Hello World')],
          total: 11,
          lineFragments: [_line('Goodbye', charStart: 0)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a rejected mismatch carries no character mapping', () {
      final layout = build(
        fragments: [_text('Hello World')],
        total: 11,
        lineFragments: [_line('Goodbye', charStart: 0)],
        suppress: true,
      );

      expect(layout.hasCharacterMapping, isFalse);
      expect(layout.spans, isEmpty);
    });

    test('rejects a fragment running past the chapter total', () {
      expect(
        () => build(
          fragments: [_text('Hello')],
          total: 5,
          lineFragments: [
            _line('Hello', charStart: 0, charEnd: 50),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects overlapping fragments', () {
      expect(
        () => build(
          fragments: [_text('HelloWorld')],
          total: 10,
          lineFragments: [
            _line('Hello', charStart: 0, charEnd: 6),
            _line('World', charStart: 3, charEnd: 10),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts a fragment whose range includes trailing whitespace', () {
      // The tolerated case, and the reason the comparison ignores whitespace. A
      // fragment's accounted range can include the space trimmed at the break
      // that follows it, so the flow text at that range holds one character
      // more than the fragment's own text. A strict comparison would reject a
      // perfectly good layout, which would cost the chapter its highlight.
      const text = 'Hello World';
      final layout = build(
        fragments: [_text(text)],
        total: text.length,
        lineFragments: [
          _line('Hello', charStart: 0, charEnd: 6, y: 0, lineIndex: 0),
          _line('World', charStart: 6, y: 20, lineIndex: 1),
        ],
      );

      expect(layout.hasCharacterMapping, isTrue);
    });
  });
}

ChapterTextLayout build({
  required List<LayoutFragment> fragments,
  required int total,
  List<LayoutLineFragment> lineFragments = const [],
  bool suppress = false,
  double contentHeight = 500,
  double viewportHeight = 1000,
}) => const ChapterTextLayoutBuilder().buildFromLayout(
  fragments: fragments,
  lineFragments: lineFragments,
  lineBounds: null,
  totalCharacterCount: total,
  contentHeight: contentHeight,
  viewportHeight: viewportHeight,
  suppressCharacterTotalAssertion: suppress,
);

LayoutFragment _text(String text) =>
    LayoutFragment(type: 'text', text: text, nodeTag: 'p');

/// Builds line fragments that tile [pieces] contiguously, one per line.
///
/// The pieces carry their own leading spaces after the first, mirroring the
/// renderer, which trims the space at a break and starts the next fragment
/// after it. Their concatenation is therefore the chapter's flow text.
List<LayoutLineFragment> _lines(List<String> pieces) {
  final result = <LayoutLineFragment>[];
  var cursor = 0;
  for (var i = 0; i < pieces.length; i++) {
    result.add(
      _line(pieces[i], charStart: cursor, y: i * 20.0, lineIndex: i),
    );
    cursor += pieces[i].length;
  }
  return result;
}

LayoutLineFragment _line(
  String piece, {
  required int charStart,
  int? charEnd,
  double y = 0,
  int lineIndex = 0,
  int? ellipsisVisibleLength,
}) => LayoutLineFragment(
  type: 'text',
  text: piece,
  charStart: charStart,
  charEnd: charEnd ?? charStart + piece.length,
  offsetX: 0,
  offsetY: y,
  width: 400,
  height: 16,
  lineIndex: lineIndex,
  nodeTag: 'p',
  ellipsisVisibleLength: ellipsisVisibleLength,
);

TextSpanBox _span(int start, int end, double y) => TextSpanBox(
  charStart: start,
  charEnd: end,
  rect: Rect.fromLTWH(0, y, 400, 20),
  nodeTag: 'p',
  type: 'text',
);

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
