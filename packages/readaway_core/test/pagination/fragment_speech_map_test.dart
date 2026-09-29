import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

/// Distinct filler of exactly [length] characters.
///
/// Every word is numbered so no two stretches of the result are
/// interchangeable. A run of identical characters cannot offer that: a span
/// could be found at the wrong offset and the search would still succeed, so a
/// test built from one measures the search's first match rather than the
/// correspondence.
String _words(int length) {
  final buffer = StringBuffer();
  var word = 0;
  while (buffer.length < length) {
    buffer.write('w$word ');
    word++;
  }
  return buffer.toString().substring(0, length);
}

/// A layout whose flow text is [flowText], split into fragments of
/// [fragmentLength] characters, one per line of height 20.
///
/// This is the shape [SpeechCharMap.fromSpans] is built for, and it is what the
/// renderer produces for a chapter of ordinary prose: many small fragments, in
/// layout order, covering the flow text.
ChapterTextLayout _layout(String flowText, {int fragmentLength = 16}) {
  final spans = <TextSpanBox>[];
  var start = 0;
  var y = 0.0;
  while (start < flowText.length) {
    final end = (start + fragmentLength) < flowText.length
        ? start + fragmentLength
        : flowText.length;
    spans.add(
      TextSpanBox(
        charStart: start,
        charEnd: end,
        rect: Rect.fromLTWH(0, y, 300, 20),
        nodeTag: '#text',
        type: 'text',
      ),
    );
    start = end;
    y += 20;
  }
  return ChapterTextLayout(
    spans: spans,
    pages: [
      PageSlice(
        index: 0,
        startY: 0,
        endY: 1000,
        startChar: 0,
        endChar: flowText.length,
      ),
    ],
    flowText: flowText,
    contentHeight: 1000,
    viewportHeight: 800,
    lineBounds: const [(top: 0.0, bottom: 1000.0)],
    totalCharacterCount: flowText.length,
  );
}

/// A layout with one span covering the whole of [flowText].
ChapterTextLayout _singleSpanLayout(String flowText) =>
    _layout(flowText, fragmentLength: flowText.length);

/// Asserts the contract that makes a map usable: every offset the map reports as
/// exact is also correct, and every offset is inside the render text.
///
/// Stated this way rather than as "every offset is right" because the
/// interpolated offsets genuinely have no right answer — that is what
/// [SpeechCharMap.isExact] is for. [truth] returns the render offset a speech
/// offset truly corresponds to.
void expectExactOffsetsAreCorrect(
  SpeechCharMap map, {
  required int Function(int speechOffset) truth,
  required int renderLength,
}) {
  var exact = 0;
  for (var i = 0; i < map.speechLength; i++) {
    final got = map.renderCharFor(i);
    expect(
      got,
      inInclusiveRange(0, renderLength),
      reason: 'offset $i is outside the render text',
    );
    if (map.isExact(i)) {
      exact++;
      expect(got, truth(i), reason: 'offset $i claimed exact');
    }
  }
  // Guard against a map that is exact nowhere, which would pass vacuously.
  expect(exact, greaterThan(0), reason: 'nothing was placed at all');
}

void main() {
  group('SpeechCharMap.fromSpans identical text', () {
    test('maps every offset one-for-one and is exact throughout', () {
      final text = _words(200);
      final map = SpeechCharMap.fromSpans(
        speech: text,
        layout: _singleSpanLayout(text),
      );

      for (var i = 0; i < text.length; i++) {
        expect(map.renderCharFor(i), i, reason: 'offset $i');
        expect(map.isExact(i), isTrue, reason: 'offset $i');
      }
      expect(map.exactFraction, 1.0);
      expect(map.speechLength, text.length);
      expect(map.renderLength, text.length);
    });

    test('empty text maps to zero and reports no correspondence', () {
      final map = SpeechCharMap.fromSpans(speech: '', layout: _layout(''));

      expect(map.renderCharFor(0), 0);
      expect(map.renderCharFor(50), 0);
      expect(map.speechLength, 0);
      expect(map.renderLength, 0);
    });

    test('clamps offsets outside the speech text to the ends', () {
      final text = _words(64);
      final map = SpeechCharMap.fromSpans(
        speech: text,
        layout: _singleSpanLayout(text),
      );

      expect(map.renderCharFor(-5), 0);
      expect(map.renderCharFor(9999), map.renderLength);
    });
  });

  group('SpeechCharMap.fromSpans fragment placement', () {
    test('places each fragment at the offset its text actually occupies', () {
      // Distinct words, so a fragment found at the wrong offset is detectable
      // rather than merely plausible.
      final flowText = _words(200);
      final map = SpeechCharMap.fromSpans(
        speech: flowText,
        layout: _layout(flowText, fragmentLength: 16),
      );

      // Every fragment is 16 characters of identical text on both sides, so the
      // correspondence inside a fragment is identity.
      for (var start = 0; start + 16 <= flowText.length; start += 16) {
        for (var i = 0; i < 16; i++) {
          expect(
            map.renderCharFor(start + i),
            start + i,
            reason: 'offset ${start + i}',
          );
        }
      }
      expect(map.exactFraction, 1.0);
    });

    test('does not mistake a repeated phrase for a later occurrence', () {
      // Every fragment here repeats a phrase, so matching one to the wrong
      // repeat would leave the following fragment unplaceable and the text
      // after it shifted. The forward-only search from the cursor is what keeps
      // the placements in order.
      const flowText =
          'repeat word 0 repeat word 1 repeat word 2 repeat word 3 '
          'tail 0 tail 1 tail 2 tail 3';
      final map = SpeechCharMap.fromSpans(
        speech: flowText,
        layout: _layout(flowText, fragmentLength: 14),
      );

      expect(map.exactFraction, 1.0, reason: 'every fragment should place');
      for (var i = 0; i < flowText.length; i++) {
        expect(map.renderCharFor(i), i, reason: 'offset $i');
      }
    });

    test('ignores a span that runs backwards rather than breaking monotonicity', () {
      // Spans are in layout order by construction, so this only guards a caller
      // that violates it. Honouring the backwards span would put the anchor list
      // out of step with itself and make every offset after it untrustworthy —
      // a failure that would not show up as a crash, only as a wrong highlight.
      final text = _words(64);
      final spans = <TextSpanBox>[
        // Deliberately out of order: a later span starting before the first.
        const TextSpanBox(
          charStart: 0,
          charEnd: 32,
          rect: Rect.fromLTWH(0, 0, 300, 20),
          nodeTag: '#text',
          type: 'text',
        ),
        const TextSpanBox(
          charStart: 16,
          charEnd: 48,
          rect: Rect.fromLTWH(0, 20, 300, 20),
          nodeTag: '#text',
          type: 'text',
        ),
        const TextSpanBox(
          charStart: 48,
          charEnd: 64,
          rect: Rect.fromLTWH(0, 40, 300, 20),
          nodeTag: '#text',
          type: 'text',
        ),
      ];
      final map = SpeechCharMap.fromSpans(
        speech: text,
        layout: ChapterTextLayout(
          spans: spans,
          pages: const [
            PageSlice(
              index: 0,
              startY: 0,
              endY: 1000,
              startChar: 0,
              endChar: 64,
            ),
          ],
          flowText: text,
          contentHeight: 1000,
          viewportHeight: 800,
          lineBounds: const [(top: 0.0, bottom: 1000.0)],
          totalCharacterCount: 64,
        ),
      );

      // The out-of-order span is dropped, so 16..48 is never placed. The two
      // spans in order both place, which covers 0..32 and 48..64, and the
      // speech between them is covered by a gap bounded by those two.
      expect(map.renderCharFor(31), 31, reason: 'first span placed');
      expect(map.renderCharFor(63), 63, reason: 'third span placed');
      expect(map.isExact(31), isTrue);
      expect(map.isExact(63), isTrue);
      // Offset 40 is in the gap rather than a placed span, and is still exact
      // because this fixture's two sides are the same string: speech 40 is
      // render 40 whatever else is true of it.
      expect(map.isExact(40), isTrue);

      // And the point of dropping the span: every offset still has a render
      // position, and those positions do not go backwards.
      var previous = -1;
      for (var i = 0; i < map.speechLength; i++) {
        final render = map.renderCharFor(i);
        expect(render, greaterThanOrEqualTo(previous), reason: 'offset $i');
        expect(render, inInclusiveRange(0, text.length), reason: 'offset $i');
        previous = render;
      }
    });
  });

  group('SpeechCharMap.fromSpans text the speech side omits', () {
    // The case the chapter-wide diff cannot survive: a block the speech side
    // skips, longer than any resynchronisation lookahead. The diff walks both
    // strings forward in step through the skipped region and never comes back.
    const head = 'The chapter opens here. ';
    const middle = 'And then it goes on. ';

    /// Speech [head] + [middle] against a render text of [head] + [size]
    /// unpronounceable characters + [middle].
    ///
    /// The correspondence is identity across [head] and shifted by [size]
    /// across [middle]; the only offsets with no single right answer are those
    /// in the fragment straddling the start of the skipped block.
    SpeechCharMap mapFor(int size, {int fragmentLength = 16}) {
      final flowText = '$head${'x' * size}$middle';
      return SpeechCharMap.fromSpans(
        speech: '$head$middle',
        layout: _layout(flowText, fragmentLength: fragmentLength),
      );
    }

    /// [head] fills speech 0 to [head.length) and render 0 to the same, so those
    /// offsets correspond to themselves. [middle] follows the skipped block, so
    /// its offsets are shifted by exactly the block's length.
    int Function(int) truthFor(int size) =>
        (i) => i < head.length ? i : i + size;

    test('every offset it calls exact is correct', () {
      for (final size in [50, 200, 800]) {
        expectExactOffsetsAreCorrect(
          mapFor(size),
          truth: truthFor(size),
          renderLength: head.length + size + middle.length,
        );
      }
    });

    test('a marker the renderer does not speak is pinned, not guessed', () {
      // The speech text opens with something the renderer does not show, so the
      // first fragment is abandoned and nothing behind speech 0 has been
      // verified. But the whole of the speech side of that gap is the tail of
      // its render side, which says where speech 0 lands without guessing: the
      // marker is exactly two characters wide, so speech 0 is render 2.
      //
      // Interpolating from a seed at render zero would put it at zero — the
      // marker itself, two characters of highlighting on the wrong text.
      final flowText = 'xx${'w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12'}';
      final speech = flowText.substring(2);
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 16),
      );

      expect(map.renderCharFor(0), 2);
      expect(map.isExact(0), isTrue, reason: 'pinned by string identity');
      expectExactOffsetsAreCorrect(
        map,
        truth: (i) => i + 2,
        renderLength: flowText.length,
      );
      expect(map.isExact(16), isTrue);
      expect(map.renderCharFor(16), 18);
    });

    test('a gap whose shape cannot be recovered is reported uncertain', () {
      // The speech side drops a block out of the middle of a line, so the
      // fragment covering that line has no counterpart anywhere in the speech
      // text, and the gap over it is not one of the recoverable shapes. Its
      // offsets are estimates and are reported as such — an offset that is
      // right by luck must not be advertised as right by measurement.
      final map = mapFor(200);

      var uncertain = 0;
      for (var i = 0; i < map.speechLength; i++) {
        if (!map.isExact(i)) uncertain++;
      }
      expect(
        uncertain,
        greaterThan(0),
        reason: 'a skipped block is uncertainty',
      );
      // And it is bounded: the rest of the chapter is still placed by identity.
      expect(map.exactFraction, greaterThan(0.8));
    });

    test(
      'the shift is the size of the skipped block, not an approximation',
      () {
        for (final size in [50, 200, 800]) {
          final map = mapFor(size);
          // The last speech character sits in [middle], so it is exactly [size]
          // characters further along than its own offset.
          final last = head.length + middle.length - 1;
          expect(map.renderCharFor(last), last + size, reason: 'skipped $size');
          expect(map.isExact(last), isTrue, reason: 'skipped $size');
        }
      },
    );

    test('the uncertain region is bounded by a fragment, not by the block', () {
      // The point of the whole exercise. Skipping 800 characters must not leave
      // 800 characters of uncertainty, nor must it move the error found at 50.
      int fuzzyWidth(int size) {
        final map = mapFor(size);
        var width = 0;
        for (var i = 0; i < map.speechLength; i++) {
          if (!map.isExact(i)) width++;
        }
        return width;
      }

      // Bounded by the fragment that straddles the start of the block, whose
      // position within the grid depends on the block's size modulo the
      // fragment length. So the width is stable to within a fragment, not
      // equal, and never a fraction of the block.
      final narrow = fuzzyWidth(50);
      final wide = fuzzyWidth(800);
      expect(
        wide,
        lessThanOrEqualTo(narrow + 16),
        reason: 'grew with the block',
      );
      expect(wide, lessThanOrEqualTo(32));
      expect(
        wide,
        lessThan(800 ~/ 10),
        reason: 'uncertainty tracked the block',
      );
    });

    test('the diff does not recover, which is why it is not used', () {
      // Recorded as a contrast rather than as a requirement of this class: it
      // is the reason fromSpans exists. If `build` is ever fixed to handle this
      // case, revisit this rather than leaving it to fail silently.
      var wideError = 0;
      var narrowError = 0;
      for (final size in [50, 200, 800]) {
        final flowText = '$head${'x' * size}$middle';
        final speech = '$head$middle';
        final byDiff = SpeechCharMap.build(speech, flowText);
        final byFragment = SpeechCharMap.fromSpans(
          speech: speech,
          layout: _layout(flowText),
        );
        final last = speech.length - 1;

        expect(
          byFragment.renderCharFor(last),
          last + size,
          reason: 'skipped $size',
        );
        final error = (byDiff.renderCharFor(last) - (last + size)).abs();
        if (size == 50) narrowError = error;
        if (size == 800) wideError = error;
      }

      // A block sixteen times the size costs the fragment search nothing: its
      // answer is exact at every size. The diff's error grows with the block,
      // because the error is the part of the block its resynchronisation
      // lookahead never reached back across.
      expect(wideError, greaterThan(narrowError), reason: 'error grew');
      expect(
        wideError,
        lessThan(800 ~/ 4),
        reason: 'sanity: bounded, not runaway',
      );
    });
  });

  group('SpeechCharMap.fromSpans text the renderer omits', () {
    // A list marker: the renderer draws it, the speech side does not speak it.
    // One marker at the start of a chapter, followed by ordinary prose, is the
    // shape a real list item has once the rest of the chapter is flowing text.
    test('places the prose after a marker by identity', () {
      final flowText = '1. ${_words(200)}';
      final speech = _words(200);
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 16),
      );

      // The first fragment is "1. w0 w1 w2 " and is not in the speech text, so
      // it is abandoned. Every fragment after it is found, and the marker
      // accounts for a fixed shift rather than an accumulating one.
      expectExactOffsetsAreCorrect(
        map,
        truth: (i) => i + 3,
        renderLength: flowText.length,
      );
      // Most of the chapter is placed, not just the first fragment.
      expect(map.exactFraction, greaterThan(0.8));
      // The end of the chapter is exact, which an accumulating shift would deny.
      expect(map.renderCharFor(speech.length - 1), flowText.length - 1);
      expect(map.isExact(speech.length - 1), isTrue);
    });

    test('a chapter of markers places nothing rather than placing it wrongly', () {
      // The limit of the fragment path, recorded so it is not mistaken for a
      // defect. When every fragment contains a decoration, no fragment's text
      // is findable and the map places none of them. The result is an
      // interpolation that reports itself as entirely uncertain.
      const flowText = 'One. Two. Three. Four. Five. Six. Seven. Eight.';
      final speech = 'One Two Three Four Five Six Seven Eight';
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 6),
      );

      expect(map.exactFraction, 0.0);

      // The diff appears to do better on this text and does not. It reports the
      // whole chapter exact while being wrong at nearly every offset, because
      // it resynchronises onto each marker's trailing space and never accounts
      // for the marker. This is why the fragment path is chosen for its
      // verifiability rather than for its exactFraction: an uncertainty the
      // caller can see beats a certainty it cannot.
      final byDiff = SpeechCharMap.build(speech, flowText);
      expect(byDiff.exactFraction, 1.0, reason: 'and it is still wrong');
      expect(
        byDiff.renderCharFor(speech.length - 1),
        isNot(flowText.length - 1),
      );
    });

    test('an unplaced chapter is still monotone and in range', () {
      const flowText = 'One. Two. Three. Four. Five. Six. Seven. Eight.';
      final speech = 'One Two Three Four Five Six Seven Eight';
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 6),
      );

      var previous = -1;
      for (var i = 0; i < speech.length; i++) {
        final r = map.renderCharFor(i);
        expect(r, greaterThanOrEqualTo(previous), reason: 'offset $i');
        expect(r, inInclusiveRange(0, flowText.length), reason: 'offset $i');
        previous = r;
      }
    });
  });

  group('SpeechCharMap.fromSpans ruby', () {
    // The renderer draws the kanji base; the speech side reads the kana. The two
    // differ in length and neither can be derived from the other, so the reading
    // is the one place the correspondence cannot be established by finding text.
    late String flowText;
    late String speech;

    setUp(() {
      flowText = '${_words(60)}漢字${_words(60)}';
      speech = '${_words(60)}ひらがな${_words(60)}';
    });

    test('every offset it calls exact is correct', () {
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 20),
      );

      // Up to the reading the text is identical. The reading's own offsets have
      // no single right answer — four kana occupy two characters — so they are
      // left fuzzy. Past it the speech side runs two characters ahead, because
      // four kana are read where two kanji are drawn.
      expectExactOffsetsAreCorrect(
        map,
        truth: (i) => i <= 60 ? i : i - 2,
        renderLength: flowText.length,
      );
    });

    test('the boundary of the reading is exact, its interior is not', () {
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 20),
      );

      // Offset 60 is the end of the last placed fragment, so the correspondence
      // there is verified by identity even though the text after it differs.
      expect(map.renderCharFor(60), 60, reason: 'both sides end there');
      expect(map.isExact(60), isTrue, reason: 'a placed fragment ends here');
      // The kana that follow have no partner to be verified against.
      for (var i = 61; i < 64; i++) {
        expect(
          map.isExact(i),
          isFalse,
          reason: 'offset $i is inside the reading',
        );
      }
    });

    test('the text after a reading is exact, not merely close', () {
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 20),
      );

      // A ruby reading is where an unrecovered length difference would put the
      // speech on the wrong character, so the far end of the chapter is the
      // offset worth checking rather than the near one.
      final last = speech.length - 1;
      expect(map.renderCharFor(last), flowText.length - 1);
      expect(map.isExact(last), isTrue);
    });

    test('uncertainty spans the reading and one fragment, not the chapter', () {
      int fuzzyWidth(int readingLength) {
        final map = SpeechCharMap.fromSpans(
          speech: '${_words(60)}${'か' * readingLength}${_words(60)}',
          layout: _layout(
            '${_words(60)}${'漢' * 2}${_words(60)}',
            fragmentLength: 20,
          ),
        );
        var width = 0;
        for (var i = 0; i < map.speechLength; i++) {
          if (!map.isExact(i)) width++;
        }
        return width;
      }

      // The uncertain region is the reading — whose kana have no partner — plus
      // the fragment that straddles the base. So it tracks the length of the
      // reading, which genuinely has no correspondence, and nothing else.
      expect(
        fuzzyWidth(10),
        closeTo(fuzzyWidth(4) + 6, 1),
        reason: 'a longer reading means more kana with no partner',
      );
      // Ten kana and a straddling fragment, against a 120-character chapter.
      expect(fuzzyWidth(10), lessThanOrEqualTo(30));
      // Most of the chapter is still exact.
      expect(
        SpeechCharMap.fromSpans(
          speech: speech,
          layout: _layout(flowText, fragmentLength: 20),
        ).exactFraction,
        greaterThan(0.8),
      );
    });
  });

  group('SpeechCharMap.fromSpans unmatched layout', () {
    test('a layout with no relation to the speech text claims nothing', () {
      // Every span fails to place, so the map is an interpolation across the
      // whole chapter and reports exactly that. The alternative — an anchor
      // seeded at (0, 0) and treated as verified — would send every caller
      // chasing text the layout does not contain.
      final flowText = _words(200);
      final map = SpeechCharMap.fromSpans(
        speech: 'nothing in common here at all, not one character',
        layout: _layout(flowText),
      );

      expect(map.exactFraction, 0.0);
      var previous = -1;
      for (var i = 0; i < map.speechLength; i++) {
        final r = map.renderCharFor(i);
        expect(r, greaterThanOrEqualTo(previous), reason: 'offset $i');
        expect(r, inInclusiveRange(0, flowText.length), reason: 'offset $i');
        previous = r;
      }
    });

    test('a chapter whose two sides are identical is exact with no spans', () {
      // Nothing to place, and nothing needing to be: where the render text and
      // the speech text are the same string, every offset does correspond to
      // the offset it reports, so claiming it is true rather than convenient.
      // The case only arises when the layout reports no fragments at all, which
      // is why it sits with the unmatched ones rather than the placed ones.
      final speech = _words(64);
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: ChapterTextLayout(
          spans: const [],
          pages: const [],
          flowText: speech,
          contentHeight: 100,
          viewportHeight: 100,
          lineBounds: const [],
          totalCharacterCount: speech.length,
        ),
      );

      expect(map.exactFraction, 1.0);
      expect(map.renderCharFor(10), 10);
    });

    test('a layout with no spans has nothing to map to', () {
      final map = SpeechCharMap.fromSpans(
        speech: _words(64),
        layout: const ChapterTextLayout(
          spans: [],
          pages: [],
          flowText: '',
          contentHeight: 0,
          viewportHeight: 0,
          lineBounds: [],
          totalCharacterCount: 0,
        ),
      );

      expect(map.renderLength, 0);
      expect(map.renderCharFor(0), 0);
      expect(map.exactFraction, 0.0);
    });

    test('honours the search bound instead of scanning the whole chapter', () {
      // The speech text is the whole flow text, displaced by a block of
      // characters the layout has no geometry for. Fragments after the
      // displacement are findable, but only by looking past it — and how far
      // past is [maxSearchRun]'s decision, not this class's.
      final flowText = _words(200);
      // Longer than the default bound, so the default genuinely cannot reach
      // and the difference between bounded and unbounded is observable rather
      // than incidental.
      final gap = 'z' * 6000;
      final speech = '${_words(64)}$gap$flowText';
      final layout = _layout(flowText, fragmentLength: 16);

      // The first four fragments sit before the displacement, so they place
      // identically under either bound: the bound is a ceiling on how far to
      // look, not a limit on what is close by.
      final tight = SpeechCharMap.fromSpans(
        speech: speech,
        layout: layout,
        maxSearchRun: 16,
      );
      final wide = SpeechCharMap.fromSpans(
        speech: speech,
        layout: layout,
        maxSearchRun: gap.length + flowText.length,
      );

      expect(tight.isExact(0), isTrue);
      expect(tight.renderCharFor(32), 32);
      // Past the displacement the tight search declines to look that far, so it
      // places only the four fragments that sit before the block.
      expect(tight.exactSpeechChars, 64);
      expect(tight.exactSpeechChars, lessThan(flowText.length));

      // Given the bound to reach, every fragment is found by identity. Note the
      // speech fraction stays around 0.09 and never approaches 1.0: the gap is
      // 2000 characters of speech with nothing in the layout to correspond to,
      // and the map is right to call all of it uncertain. Counting speech
      // characters would measure the size of the gap, not the quality of the
      // mapping, so what is counted here is render text actually placed.
      int placedRenderChars(SpeechCharMap map) {
        final covered = <int>{};
        for (var i = 0; i < map.speechLength; i++) {
          if (map.isExact(i)) covered.add(map.renderCharFor(i));
        }
        return covered.length;
      }

      expect(placedRenderChars(tight), lessThan(flowText.length ~/ 2));

      // Every render character is placed, and placement is monotone in the
      // speech offsets. The fragments before the gap land in the first copy of
      // the flow text at the start of the speech text; the rest are only
      // findable in the second copy, after it.
      //
      // A render character can legitimately be placed at two speech offsets —
      // a fragment boundary is the end of one fragment and the start of the
      // next, and both are verified identities. So the check is that the whole
      // of the render text is covered and that the mapping never goes
      // backwards, not that each render offset is claimed once.
      final covered = <int>{};
      var previousRender = -1;
      for (var i = 0; i < wide.speechLength; i++) {
        if (!wide.isExact(i)) continue;
        final render = wide.renderCharFor(i);
        expect(
          render,
          greaterThanOrEqualTo(previousRender),
          reason: 'speech $i',
        );
        previousRender = render;
        covered.add(render);
      }
      expect(
        covered.length,
        flowText.length,
        reason: 'every render char placed',
      );

      // The default is finite on purpose: a chapter whose speech text bears no
      // relation to its layout must not cost a scan per fragment.
      final byDefault = SpeechCharMap.fromSpans(speech: speech, layout: layout);
      expect(
        placedRenderChars(byDefault),
        lessThan(placedRenderChars(wide)),
        reason: 'the default bound cannot reach across the gap',
      );
    });
  });

  group('SpeechCharMap.fromSpans invariants', () {
    test('is monotone in both directions across a mixed chapter', () {
      // Prose, a long skipped block, a marker and a ruby reading in one
      // chapter: the case with the most opportunity to lose place.
      final head = _words(80);
      final mid = _words(80);
      final tail = _words(80);
      final skipped = List.filled(150, 'q').join();
      final flowText = '$head$skipped $mid 1. $tail漢字';
      final speech = '$head $mid $tail ひらがな';

      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _layout(flowText, fragmentLength: 24),
      );

      var previousRender = -1;
      for (var i = 0; i < map.speechLength; i++) {
        final r = map.renderCharFor(i);
        expect(r, greaterThanOrEqualTo(previousRender), reason: 'offset $i');
        expect(r, inInclusiveRange(0, flowText.length), reason: 'offset $i');
        previousRender = r;
      }

      var previousSpeech = -1;
      for (var i = 0; i < flowText.length; i++) {
        final s = map.speechCharFor(i);
        expect(s, greaterThanOrEqualTo(previousSpeech), reason: 'offset $i');
        expect(s, inInclusiveRange(0, map.speechLength), reason: 'offset $i');
        previousSpeech = s;
      }
    });

    test('speech past the last fragment is not claimed', () {
      final flowText = _words(64);
      final speech = '${_words(64)} and trailing speech with no fragment';
      final map = SpeechCharMap.fromSpans(
        speech: speech,
        layout: _singleSpanLayout(flowText),
      );

      // Nothing verified the trailing speech, so it is uncertain rather than
      // pinned to the end of the render text.
      expect(map.isExact(speech.length - 1), isFalse);
      expect(map.renderCharFor(speech.length - 1), map.renderLength);
    });

    test('the inverse map returns to speech from any render offset', () {
      final text = _words(120);
      final map = SpeechCharMap.fromSpans(
        speech: text,
        layout: _layout(text, fragmentLength: 24),
      );

      for (var i = 0; i < text.length; i++) {
        expect(map.speechCharFor(map.renderCharFor(i)), i, reason: 'offset $i');
      }
    });
  });
}
