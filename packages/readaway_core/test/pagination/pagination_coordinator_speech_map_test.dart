import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

/// Distinct filler of exactly [length] characters.
///
/// Every word is numbered, so no two stretches of the result are
/// interchangeable. A run of identical characters cannot offer that: every
/// alignment of it matches as well as every other, and the matcher is free to
/// prefer a shifted one, which shows up as a mapping that is quietly off by a
/// character while still claiming to be exact.
String _distinct(int length) {
  final buffer = StringBuffer();
  var word = 0;
  while (buffer.length < length) {
    buffer.write('w$word ');
    word++;
  }
  return buffer.toString().substring(0, length);
}

/// A chapter's two sides: the rendered flow text and the text the speech side
/// reads. [head] and [tail] are what the renderer shows and the speech side
/// does not speak — a list marker, a footnote — so every speech offset after the
/// head is [head.length] further along in the flow text, and after the tail it
/// is [head.length] + [tail.length].
///
/// Both sides are cut from one continuous run of [_distinct] filler, with
/// [head] added in front and [tail] spliced into the middle of the render side
/// only. That is what makes the fixture falsifiable. Filler of one repeated
/// character cannot be matched at all — every alignment of it matches as well as
/// every other, so any answer is right by luck — and neither can two separate
/// runs of numbered filler, which share a prefix and are interchangeable for
/// exactly as long as that prefix. Numbering continuously means no stretch of
/// one side can be found in the other except where it belongs.
({String flow, String speech}) _flow({
  String head = '',
  int middle = 0,
  String tail = '',
  int tailFiller = 0,
}) {
  final body = _distinct(middle + tailFiller);
  return (
    flow: '$head${body.substring(0, middle)}$tail${body.substring(middle)}',
    speech: body,
  );
}

/// Three pages of 250 characters each: 0-249, 250-499, 500-749, with the text
/// broken into lines of 25 the way the renderer reports it. Ten lines to a
/// page, a hundred units to a line, so line *k* sits at y = 100k.
///
/// The line size matters to the correspondence, not just to the geometry. A span
/// is a render range the renderer measured, and `SpeechCharMap.fromSpans` places
/// one only by finding its exact text in the speech text, so a span wider than
/// the decorated region it covers cannot be placed at all: the wider the spans,
/// the more of the chapter a single ruby reading or list marker can spoil.
/// Page-sized spans would make that the normal case rather than the exceptional
/// one, and would measure the fixture rather than the reader.
ChapterTextLayout _layout({String? flowText}) {
  const lineLength = 25;
  const lineHeight = 100.0;
  final text = flowText ?? _distinct(750);
  final spans = <TextSpanBox>[];
  for (var start = 0; start < text.length; start += lineLength) {
    final end = (start + lineLength) < text.length
        ? start + lineLength
        : text.length;
    spans.add(
      TextSpanBox(
        charStart: start,
        charEnd: end,
        rect: Rect.fromLTWH(0, (start ~/ lineLength) * lineHeight, 400, 20),
        nodeTag: 'p',
        type: 'text',
      ),
    );
  }
  return ChapterTextLayout(
    contentHeight: 3000,
    viewportHeight: 1000,
    lineBounds: const [],
    spans: spans,
    pages: const [
      PageSlice(index: 0, startY: 0, endY: 1000, startChar: 0, endChar: 250),
      PageSlice(
        index: 1,
        startY: 1000,
        endY: 2000,
        startChar: 250,
        endChar: 500,
      ),
      PageSlice(
        index: 2,
        startY: 2000,
        endY: 3000,
        startChar: 500,
        endChar: 750,
      ),
    ],
    flowText: text,
    totalCharacterCount: text.length,
  );
}

PaginationCoordinator _coordinator() {
  final coordinator = PaginationCoordinator();
  coordinator.initialize(
    chapterCount: 1,
    viewportHeight: 1000,
    contentHeight: 3000,
  );
  return coordinator;
}

void main() {
  group('resolving a speech offset to a page', () {
    test('identical text passes offsets straight through', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, _distinct(750));

      expect(coordinator.speechMapFor(0), isNotNull);
      expect(coordinator.pageForSpeechOffset(0, 0), 0);
      expect(coordinator.pageForSpeechOffset(0, 249), 0);
      expect(coordinator.pageForSpeechOffset(0, 250), 1);
      expect(coordinator.pageForSpeechOffset(0, 500), 2);
    });

    test('accounts for text the renderer adds', () {
      final coordinator = _coordinator();
      // The render side carries six extra leading characters, as it would with
      // a list marker. Every speech offset therefore sits six further along.
      // The marker is spelled out because a run of identical characters would
      // be indistinguishable from the text around it.
      final chapter = _flow(head: 'MARKER', middle: 750);
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: chapter.flow),
      );
      coordinator.attachSpeechText(0, chapter.speech);

      // Offset 200 lands on render 220, still page 0.
      expect(coordinator.pageForSpeechOffset(0, 200), 0);
      // Offset 245 lands on render 265, which is page 1. Assuming a one-to-one
      // correspondence would place it on render 245 and wrongly report page 0.
      expect(coordinator.pageForSpeechOffset(0, 245), 1);
    });

    test('accounts for text the speech side omits', () {
      final coordinator = _coordinator();
      // The renderer shows a footnote container the speech side never reads.
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(
          flowText: _flow(middle: 250, tail: 'A note.', tailFiller: 500).flow,
        ),
      );
      coordinator.attachSpeechText(
        0,
        _flow(middle: 250, tail: 'A note.', tailFiller: 500).speech,
      );

      // Speech 200 is the 200th spoken character, which the renderer reaches at
      // 200 because the footnote comes later in the flow.
      expect(coordinator.pageForSpeechOffset(0, 200), 0);
      // Speech 300 is past the footnote, so the renderer is 7 further along.
      expect(coordinator.speechMapFor(0)!.renderCharFor(300), 307);
      expect(coordinator.pageForSpeechOffset(0, 300), 1);
    });
  });

  group('the two sides may arrive in either order', () {
    test('layout first, then speech text', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());

      expect(coordinator.speechMapFor(0), isNull);
      // Null rather than 0, so a caller can tell "unknown" from "page zero".
      expect(coordinator.pageForSpeechOffset(0, 250), isNull);
      expect(coordinator.speechOffsetForChar(0, 250), isNull);
      expect(coordinator.isSpeechOffsetExact(0, 0), isFalse);

      coordinator.attachSpeechText(0, _distinct(750));
      expect(coordinator.speechMapFor(0), isNotNull);
      expect(coordinator.pageForSpeechOffset(0, 250), 1);
    });

    test('speech text first, then layout', () {
      final coordinator = _coordinator();
      coordinator.attachSpeechText(0, _distinct(750));
      expect(coordinator.speechMapFor(0), isNull);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      expect(coordinator.speechMapFor(0), isNotNull);
      expect(coordinator.pageForSpeechOffset(0, 250), 1);
    });

    test('speech text survives until a layout arrives', () {
      final coordinator = _coordinator();
      // An unusable layout must not discard the text, or a later measurement
      // would have nothing to align against.
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: ChapterTextLayout.unavailable(
          contentHeight: 3000,
          viewportHeight: 1000,
          lineBounds: const [],
        ),
      );
      coordinator.attachSpeechText(0, _distinct(750));
      expect(coordinator.speechMapFor(0), isNull);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      expect(coordinator.speechMapFor(0), isNotNull);
    });
  });

  group('invalidation', () {
    test('a relayout rebuilds the map against the new flow text', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, _distinct(750));
      expect(coordinator.pageForSpeechOffset(0, 245), 0);

      // A relayout can change the flow text, e.g. a wider viewport changes
      // which elements are rendered as list items. The map must follow rather
      // than keep the old answer.
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: _flow(head: 'MARKER', middle: 750).flow),
      );

      expect(coordinator.pageForSpeechOffset(0, 245), 1);
    });

    test('an unchanged relayout does not discard the map', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, _distinct(750));
      expect(coordinator.speechMapFor(0), isNotNull);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      expect(coordinator.speechMapFor(0), isNotNull);
    });

    test('a plain height change drops the map and its text', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, _distinct(750));
      expect(coordinator.speechMapFor(0), isNotNull);

      coordinator.registerChapterHeight(chapterIndex: 0, contentHeight: 2500);

      expect(coordinator.speechMapFor(0), isNull);
    });

    test('invalidate and reset drop the map and its text', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, _distinct(750));
      coordinator.invalidate();
      expect(coordinator.speechMapFor(0), isNull);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, _distinct(750));
      coordinator.reset();
      expect(coordinator.speechMapFor(0), isNull);
    });
  });

  group('speechOffsetForChar', () {
    test('inverts the forward mapping', () {
      final coordinator = _coordinator();
      final chapter = _flow(head: 'MARKER', middle: 750);
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: chapter.flow),
      );
      coordinator.attachSpeechText(0, chapter.speech);
      final map = coordinator.speechMapFor(0)!;

      for (var speech = 0; speech < 750; speech += 25) {
        expect(
          coordinator.speechOffsetForChar(0, map.renderCharFor(speech)),
          speech,
        );
      }
    });
  });

  group('isSpeechOffsetExact', () {
    test('a chapter that is nothing but a divergence claims nothing', () {
      // Five characters, one line fragment covering all of them, and a reading
      // that the renderer draws as three kana the speech side does not speak.
      // There is no second fragment to place, so nothing has been matched
      // against anything and no offset is reported exact — offset 0 included,
      // even though it is right. That is the floor of what the guarantee is
      // worth: exact means a fragment was found by identity, and here none was.
      //
      // The floor costs a position, not a highlight.
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: 'AugaB'),
      );
      coordinator.attachSpeechText(0, 'AひらがなB');

      expect(coordinator.isSpeechOffsetExact(0, 0), isFalse);
      expect(coordinator.isSpeechOffsetExact(0, 2), isFalse);
      expect(coordinator.rectsForSpeechRange(0, 0, 3), isNotEmpty);
    });
  });

  group('Japanese ruby', () {
    // The one divergence that cannot be resolved by matching: the renderer
    // draws the kanji base while the speech side reads the kana, and the two
    // differ in length. The kana are not recoverable from the render side, so
    // offsets inside the span are interpolated and the two extra characters are
    // absorbed by shifting everything after it.
    //
    // The fixture puts the reading immediately before a page boundary, which is
    // where an unrecovered length difference silently puts the speech on the
    // wrong page.
    final head = _distinct(244);
    final tail = _distinct(503);
    final render = '$head${'KAN'}$tail';
    final speech = '$head${'よみがなわ'}$tail';

    PaginationCoordinator rubyCoordinator() {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: render),
      );
      coordinator.attachSpeechText(0, speech);
      return coordinator;
    }

    test('the fixture is the length difference it claims to be', () {
      // Three kanji against five kana: the speech side runs two characters
      // ahead from the reading onwards, and never catches up.
      expect(render.length, 750);
      expect(speech.length, 752);
      expect(render.substring(244, 247), 'KAN');
      expect(speech.substring(244, 249), 'よみがなわ');
    });

    test('passes text before the reading through unchanged', () {
      final map = rubyCoordinator().speechMapFor(0)!;

      // The two sides carry identical text up to the reading, and every offset
      // in a placed fragment is a verified correspondence rather than an
      // estimate. The reading sits inside the fragment that straddles it, so
      // exactness stops where that fragment starts — not where the reading
      // does, which cannot be known without recovering the kana.
      for (final offset in [0, 1, 100, 200, 224, 225]) {
        expect(map.renderCharFor(offset), offset, reason: 'offset $offset');
        expect(map.isExact(offset), isTrue, reason: 'offset $offset');
      }
    });

    test('shifts later offsets by the length the reading adds', () {
      final map = rubyCoordinator().speechMapFor(0)!;

      // Past the reading the speech side is two characters further along, and
      // every such offset in a placed fragment is still exact because the text
      // there is identical.
      for (final offset in [252, 253, 300, 500, 600, 751]) {
        expect(map.renderCharFor(offset), offset - 2, reason: 'offset $offset');
        expect(map.isExact(offset), isTrue, reason: 'offset $offset');
      }
    });

    test('is within the length of the reading wherever it is approximate', () {
      final map = rubyCoordinator().speechMapFor(0)!;

      // Across the reading the correspondence cannot be recovered by matching —
      // the kana are not on the render side at all — so the offsets in the
      // fragment that straddles it are interpolated between the two verified
      // fragments on either side. That spreads a difference of two over
      // twenty-seven, which is wrong by at most the length of the reading: two
      // characters, half a word, and nothing a highlight at sentence size can
      // show.
      for (var offset = 0; offset < speech.length; offset++) {
        final truth = offset < 244
            ? offset
            : offset > 248
            ? offset - 2
            : null;
        if (truth == null) continue;
        expect(
          (map.renderCharFor(offset) - truth).abs(),
          lessThanOrEqualTo(2),
          reason: 'offset $offset',
        );
      }
    });

    test(
      'is approximate across the straddling fragment, not the reading alone',
      () {
        final map = rubyCoordinator().speechMapFor(0)!;

        // The kana occupy speech 244-248, but the fragment holding them also
        // holds prose either side of them, and none of that can be matched
        // either. So the whole fragment is reported approximate — twenty-six
        // offsets — and everything past it is exact again.
        expect(map.isExact(225), isTrue);
        for (var offset = 226; offset <= 251; offset++) {
          expect(map.isExact(offset), isFalse, reason: 'offset $offset');
        }
        expect(map.isExact(252), isTrue);
        expect(map.exactFraction, lessThan(1.0));
      },
    );

    test('keeps the speech on the page holding the kanji', () {
      final coordinator = rubyCoordinator();

      // The page break is at render 250, which the reading has pushed to speech
      // 252. Reading the offsets one to one would put the break at 250 and
      // strand the last two characters of the page on the wrong side.
      expect(coordinator.pageForSpeechOffset(0, 250), 0);
      expect(coordinator.pageForSpeechOffset(0, 251), 0);
      expect(coordinator.pageForSpeechOffset(0, 252), 1);
      expect(coordinator.pageForSpeechOffset(0, 500), 1);
      expect(coordinator.pageForSpeechOffset(0, 502), 2);
    });

    test('places every offset on a page that exists', () {
      final coordinator = rubyCoordinator();

      // A whole-chapter sweep is what a reader would experience, and no offset
      // may land outside the three pages.
      for (var offset = 0; offset < speech.length; offset++) {
        expect(
          coordinator.pageForSpeechOffset(0, offset),
          inInclusiveRange(0, 2),
          reason: 'offset $offset',
        );
      }
    });
  });

  group('globalPageForSpeechOffset', () {
    test('offsets by the chapter\'s position in the document', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 3,
        viewportHeight: 1000,
        contentHeight: 3000,
      );
      // Three chapters, three pages each, nine pages in total.
      for (var chapter = 0; chapter < 3; chapter++) {
        coordinator.registerChapterHeight(
          chapterIndex: chapter,
          contentHeight: 3000,
        );
        coordinator.registerChapterLayout(
          chapterIndex: chapter,
          layout: _layout(),
        );
        coordinator.attachSpeechText(chapter, _distinct(750));
      }

      expect(coordinator.pageForSpeechOffset(1, 250), 1);
      expect(coordinator.globalPageForSpeechOffset(1, 250), 4);
      expect(coordinator.globalPageForSpeechOffset(2, 500), 8);
    });

    test('is null without a correspondence', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());

      expect(coordinator.globalPageForSpeechOffset(0, 250), isNull);
    });
  });

  group('rectsForSpeechRange', () {
    test('covers the range the speech text occupies', () {
      final coordinator = _coordinator();
      // Each of the three spans covers 250 characters on its own page.
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, _distinct(750));

      // Speech 260-270 lives in the second span.
      final rects = coordinator.rectsForSpeechRange(0, 260, 270);
      expect(rects, isNotEmpty);
      for (final rect in rects) {
        expect(rect.top, 1000);
      }
    });

    test('is empty without a correspondence', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());

      // Empty rather than a guessed position: a highlight with nothing to
      // paint is better than one drawn in the wrong place.
      expect(coordinator.rectsForSpeechRange(0, 0, 100), isEmpty);
    });

    test('accounts for text the renderer adds', () {
      final coordinator = _coordinator();
      final chapter = _flow(head: 'MARKER', middle: 750);
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: chapter.flow),
      );
      coordinator.attachSpeechText(0, chapter.speech);

      // Speech 200 is on page 0. The marker's six characters push it six
      // further into the render text, which is still inside the eighth line,
      // so the highlight lands there. Speech 245 crosses the page boundary at
      // render 250 and lands on the eleventh line, on page 1.
      final onFirstPage = coordinator.rectsForSpeechRange(0, 200, 210);
      expect(onFirstPage, isNotEmpty);
      expect(onFirstPage.first.top, 800);

      final onSecondPage = coordinator.rectsForSpeechRange(0, 245, 255);
      expect(onSecondPage, isNotEmpty);
      expect(onSecondPage.first.top, 1000);
    });
  });
}
