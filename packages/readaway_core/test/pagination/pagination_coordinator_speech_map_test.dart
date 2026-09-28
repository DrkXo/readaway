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

/// Rendered flow text: [head], then [middle] copies of filler, then [tail],
/// then [tailFiller] more copies of filler.
///
/// The filler is a run of identical characters, so any part of the text it
/// stands in for must be spelled out in [head] or [tail] to stay
/// distinguishable. Two runs of filler are otherwise interchangeable, and no
/// matcher can tell an insertion from the text around it.
String _flow({
  String head = '',
  int middle = 0,
  String tail = '',
  int tailFiller = 0,
}) =>
    (StringBuffer(head)
          ..write('x' * middle)
          ..write(tail)
          ..write('x' * tailFiller))
        .toString();

/// Three pages of 250 characters each: 0-249, 250-499, 500-749.
ChapterTextLayout _layout({String? flowText}) => ChapterTextLayout(
  contentHeight: 3000,
  viewportHeight: 1000,
  lineBounds: const [],
  spans: [
    TextSpanBox(
      charStart: 0,
      charEnd: 250,
      rect: Rect.fromLTWH(0, 0, 400, 20),
      nodeTag: 'p',
      type: 'text',
    ),
    TextSpanBox(
      charStart: 250,
      charEnd: 500,
      rect: Rect.fromLTWH(0, 1000, 400, 20),
      nodeTag: 'p',
      type: 'text',
    ),
    TextSpanBox(
      charStart: 500,
      charEnd: 750,
      rect: Rect.fromLTWH(0, 2000, 400, 20),
      nodeTag: 'p',
      type: 'text',
    ),
  ],
  blocks: const [],
  pages: const [
    PageSlice(index: 0, startY: 0, endY: 1000, startChar: 0, endChar: 250),
    PageSlice(index: 1, startY: 1000, endY: 2000, startChar: 250, endChar: 500),
    PageSlice(index: 2, startY: 2000, endY: 3000, startChar: 500, endChar: 750),
  ],
  flowText: flowText ?? 'x' * 750,
  totalCharacterCount: 750,
);

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
      coordinator.attachSpeechText(0, 'x' * 750);

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
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: _flow(head: 'MARKER', middle: 750)),
      );
      coordinator.attachSpeechText(0, 'x' * 750);

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
          flowText: _flow(middle: 250, tail: 'A note.', tailFiller: 500),
        ),
      );
      coordinator.attachSpeechText(0, 'x' * 750);

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

      coordinator.attachSpeechText(0, 'x' * 750);
      expect(coordinator.speechMapFor(0), isNotNull);
      expect(coordinator.pageForSpeechOffset(0, 250), 1);
    });

    test('speech text first, then layout', () {
      final coordinator = _coordinator();
      coordinator.attachSpeechText(0, 'x' * 750);
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
      coordinator.attachSpeechText(0, 'x' * 750);
      expect(coordinator.speechMapFor(0), isNull);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      expect(coordinator.speechMapFor(0), isNotNull);
    });
  });

  group('invalidation', () {
    test('a relayout rebuilds the map against the new flow text', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, 'x' * 750);
      expect(coordinator.pageForSpeechOffset(0, 245), 0);

      // A relayout can change the flow text, e.g. a wider viewport changes
      // which elements are rendered as list items. The map must follow rather
      // than keep the old answer.
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: _flow(head: 'MARKER', middle: 750)),
      );

      expect(coordinator.pageForSpeechOffset(0, 245), 1);
    });

    test('an unchanged relayout does not discard the map', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, 'x' * 750);
      expect(coordinator.speechMapFor(0), isNotNull);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      expect(coordinator.speechMapFor(0), isNotNull);
    });

    test('a plain height change drops the map and its text', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, 'x' * 750);
      expect(coordinator.speechMapFor(0), isNotNull);

      coordinator.registerChapterHeight(chapterIndex: 0, contentHeight: 2500);

      expect(coordinator.speechMapFor(0), isNull);
    });

    test('invalidate and reset drop the map and its text', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, 'x' * 750);
      coordinator.invalidate();
      expect(coordinator.speechMapFor(0), isNull);

      coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());
      coordinator.attachSpeechText(0, 'x' * 750);
      coordinator.reset();
      expect(coordinator.speechMapFor(0), isNull);
    });
  });

  group('speechOffsetForChar', () {
    test('inverts the forward mapping', () {
      final coordinator = _coordinator();
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: _flow(head: 'MARKER', middle: 750)),
      );
      coordinator.attachSpeechText(0, 'x' * 750);
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
    test('reports exactness through the coordinator', () {
      final coordinator = _coordinator();
      // The renderer shows 'uga' where the speech side reads three kana.
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: 'AugaB'),
      );
      coordinator.attachSpeechText(0, 'AひらがなB');

      expect(coordinator.isSpeechOffsetExact(0, 0), isTrue);
      expect(coordinator.isSpeechOffsetExact(0, 2), isFalse);
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
      // there is a verified correspondence rather than an estimate.
      for (final offset in [0, 1, 100, 200, 243, 244]) {
        expect(map.renderCharFor(offset), offset, reason: 'offset $offset');
        expect(map.isExact(offset), isTrue, reason: 'offset $offset');
      }
    });

    test('shifts later offsets by the length the reading adds', () {
      final map = rubyCoordinator().speechMapFor(0)!;

      // Past the reading the speech side is two characters further along, and
      // every such offset is still exact because the text there is identical.
      for (final offset in [249, 250, 300, 500, 600, 751]) {
        expect(map.renderCharFor(offset), offset - 2, reason: 'offset $offset');
        expect(map.isExact(offset), isTrue, reason: 'offset $offset');
      }
    });

    test('reports only the reading itself as approximate', () {
      final map = rubyCoordinator().speechMapFor(0)!;

      // The kana occupy speech 244-248; their endpoints are the points the
      // matcher resynchronised on, so only the interior is an estimate.
      expect(map.isExact(244), isTrue);
      expect(map.isExact(249), isTrue);
      for (final offset in [245, 246, 247, 248]) {
        expect(map.isExact(offset), isFalse, reason: 'offset $offset');
      }
      expect(map.exactFraction, lessThan(1.0));
    });

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
        coordinator.attachSpeechText(chapter, 'x' * 750);
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
      coordinator.attachSpeechText(0, 'x' * 750);

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
      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _layout(flowText: _flow(head: 'MARKER', middle: 750)),
      );
      coordinator.attachSpeechText(0, 'x' * 750);

      // Speech 200 is on page 0, but the marker's six characters push it
      // into the first span, so it stays there. Speech 245 crosses the
      // boundary and lands on the second span's page.
      final onFirstPage = coordinator.rectsForSpeechRange(0, 200, 210);
      expect(onFirstPage, isNotEmpty);
      expect(onFirstPage.first.top, 0);

      final onSecondPage = coordinator.rectsForSpeechRange(0, 245, 255);
      expect(onSecondPage, isNotEmpty);
      expect(onSecondPage.first.top, 1000);
    });
  });
}
