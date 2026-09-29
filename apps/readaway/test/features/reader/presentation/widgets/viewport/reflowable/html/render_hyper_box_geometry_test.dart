import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart'
    show HyperViewer, RenderHyperBox;
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/chapter_text_layout_builder.dart';
import 'package:readaway_core/readaway_core.dart';

/// Walks a render subtree for the [RenderHyperBox] that owns the chapter's
/// laid-out geometry, mirroring `ReflowableVirtualPage._findHyperBox`.
RenderHyperBox? findHyperBox(RenderObject? root) {
  if (root == null) return null;
  if (root is RenderHyperBox) return root;
  RenderHyperBox? found;
  root.visitChildren((child) => found ??= findHyperBox(child));
  return found;
}

/// Long enough that it cannot fit on one line at 300px, short enough to keep
/// the test fast. The test font gives every glyph the same advance width, so
/// the wrap points are deterministic.
const wrappingParagraph =
    '<p>The quick brown fox jumps over the lazy dog while the reader turns '
    'another page of a long chapter without pausing to consider what any of it '
    'was for in the first place.</p>';

const singleLineParagraph = '<p>Short line.</p>';

/// A chapter of ordinary prose: a heading, several paragraphs, a list, a quoted
/// passage and an emphasised run. Long enough to run to several pages, which is
/// where the tiling question can actually be asked.
const realisticChapter = '''
<h1>The Shape of a Chapter</h1>
<p>A chapter is not a wall of text, however much it may feel like one when the
reader is halfway through it and has stopped noticing the words. It is an
argument with a shape, and the shape is what lets a reader who has been
interrupted find their way back in.</p>
<p>This is why the layout work matters more than it appears to. A reader who
loses their place does not lose a sentence; they lose the thread, and the
thread is carried by the paragraph breaks, the heading above them, and the
occasional list that says <em>here is a list</em> rather than leaving them to
work out whether the lines they are reading belong together.</p>
<ul>
  <li>The heading says what kind of passage this is.</li>
  <li>The list says what the enumeration is enumerating.</li>
  <li>The quotation says the words are somebody else's.</li>
</ul>
<blockquote>
  <p>A page is a decision about what not to put on it. Every element the reader
  scrolls past is an argument they had to win first.</p>
</blockquote>
<p>None of that is visible as a feature. It is visible as a page that can be
skimmed, which is the whole of what a page is for, and which is exactly as
hard to get right as it is easy to take for granted.</p>
''';

/// The characters the paragraph contributes, so a test can compare them with
/// what the renderer reports without hardcoding a length.
String _stripTags(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '');

void main() {
  Future<RenderHyperBox> pumpHtml(WidgetTester tester, String html) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 300, child: HyperViewer(html: html)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final box = findHyperBox(
      find.byType(HyperViewer).evaluate().first.renderObject,
    );
    expect(box, isNotNull, reason: 'HyperViewer produced no RenderHyperBox');
    return box!;
  }

  /// Replays the builder's accounting over [box]'s fragments, so the test can
  /// distinguish "the offsets are wrong" from "the geometry is missing".
  int reconstructedTotal(RenderHyperBox box) {
    var sum = 0;
    for (final fragment in box.debugFragments()) {
      final text = fragment['text'] as String?;
      final type = fragment['type'] as String?;
      if (type == 'lineBreak') {
        sum += 1;
      } else if (text != null &&
          text.isNotEmpty &&
          (type == 'text' || type == 'ruby')) {
        sum += text.length;
      }
    }
    return sum;
  }

  group('RenderHyperBox fragment geometry', () {
    testWidgets('a paragraph that fits one line does report geometry', (
      tester,
    ) async {
      final box = await pumpHtml(tester, singleLineParagraph);

      expect(
        box.debugLines().length,
        1,
        reason: 'the premise is that this paragraph must NOT wrap',
      );

      final positioned = box.debugFragments().where(
        (f) => f['offsetX'] != null && f['offsetY'] != null,
      );
      expect(
        positioned,
        isNotEmpty,
        reason:
            'an unwrapped text node is positioned, so this is the control '
            'case that rules out "geometry is simply never populated"',
      );
    });

    testWidgets('a paragraph that wraps reports no geometry for its text', (
      tester,
    ) async {
      final box = await pumpHtml(tester, wrappingParagraph);

      expect(
        box.debugLines().length,
        greaterThan(1),
        reason: 'the paragraph must actually wrap, or this test proves nothing',
      );

      // The whole text node is a single fragment spanning every line, and it
      // carries no position. This is the defect: the renderer positions the
      // pieces it was split into, and `debugFragments` reports the fragment
      // those pieces came from.
      final textFragments = box.debugFragments().where(
        (f) => (f['text'] as String? ?? '').isNotEmpty && f['type'] == 'text',
      );
      expect(textFragments, isNotEmpty);
      expect(
        textFragments.every((f) => f['offsetX'] == null),
        isTrue,
        reason:
            'every wrapped text fragment is expected to be unpositioned; '
            'if this ever becomes false the renderer was fixed upstream and '
            'this test should be revisited rather than deleted',
      );
    });

    testWidgets(
      'the character accounting is correct even when the geometry is missing',
      (tester) async {
        // Isolates the two failures so nobody "fixes" the wrong one. The
        // prefix-sum reconstruction reproduces the render object's own
        // character total exactly, so the builder's assertion never fires and
        // the failure is silent — only the geometry is absent.
        final box = await pumpHtml(tester, wrappingParagraph);

        expect(
          reconstructedTotal(box),
          box.totalCharacterCount,
          reason: 'the offsets are right; it is only the geometry that is gone',
        );

        // `build` runs with the assertion enabled, as in production. It must not
        // throw — the point is that this failure mode is quiet.
        final layout = const ChapterTextLayoutBuilder().build(
          hyperBox: box,
          contentHeight: 200,
          viewportHeight: 100,
        );

        expect(
          layout.flowText.length,
          box.totalCharacterCount,
          reason: 'flow text is still reconstructed correctly',
        );
      },
    );
  });

  group('debugLineFragments (DrkXo fork, feat/line-fragments)', () {
    // Stage 0b. The tests above pass against the published hyper_render; these
    // require the fork. If `hyper_render_core` ever resolves from pub.dev again
    // this group fails to compile — a missing method, not a silently absent
    // highlight — which is the loud failure the plan's risk 1 asks for.
    testWidgets('covers every drawn character of a wrapped paragraph', (
      tester,
    ) async {
      final box = await pumpHtml(tester, wrappingParagraph);
      expect(box.debugLines().length, greaterThan(1));

      final fragments = box.debugLineFragments();
      expect(
        fragments,
        isNotEmpty,
        reason: 'this is the geometry the previous tests showed was absent',
      );

      // One entry per fragment across all lines, matching debugLines.
      final expected = box.debugLines().fold<int>(
        0,
        (sum, l) => sum + (l['fragmentCount'] as int),
      );
      expect(fragments.length, expected);

      for (final f in fragments) {
        expect(f['offsetX'], isA<double>());
        expect(f['offsetY'], isA<double>());
        expect(f['width'], isA<double>());
        expect(f['charStart'], isA<int>());
        expect(f['charEnd'], isA<int>());
      }

      // Ranges advance monotonically and end at the renderer's own total.
      for (var i = 1; i < fragments.length; i++) {
        expect(
          fragments[i]['charStart'] as int,
          greaterThanOrEqualTo(fragments[i - 1]['charStart'] as int),
        );
      }
      expect(
        fragments.last['charEnd'] as int,
        box.totalCharacterCount,
        reason: 'the ranges tile the character space the renderer reports',
      );
    });

    testWidgets('gaps are exactly the whitespace trimmed at a wrap', (
      tester,
    ) async {
      final box = await pumpHtml(tester, wrappingParagraph);
      final fragments = box.debugLineFragments();

      // Concatenating the fragments loses only trimmed whitespace, so a gap
      // means "not drawn" rather than "lost". A consumer that assumed
      // contiguity would smear or drop characters at every wrap.
      final joined = fragments.map((f) => f['text'] as String? ?? '').join();
      String strip(String s) => s.replaceAll(RegExp(r'\s+'), '');
      expect(strip(joined), strip(_stripTags(wrappingParagraph)));

      // Every non-whitespace character is covered by some range.
      final covered = <int>{};
      for (final f in fragments) {
        final start = f['charStart'] as int;
        final end = f['charEnd'] as int;
        for (var c = start; c < end; c++) {
          covered.add(c);
        }
      }
      final text = _stripTags(wrappingParagraph);
      for (var i = 0; i < text.length; i++) {
        if (text[i].trim().isEmpty) continue;
        expect(covered, contains(i), reason: 'character $i is drawn');
      }
    });

    testWidgets('reports the two fields debugFragments omits', (tester) async {
      final box = await pumpHtml(tester, wrappingParagraph);
      for (final f in box.debugLineFragments()) {
        expect(
          f.containsKey('rubyText'),
          isTrue,
          reason:
              'the renderer draws kanji while speech speaks kana; a '
              'consumer needs the reading to relate the two',
        );
        expect(
          f.containsKey('ellipsisVisibleLength'),
          isTrue,
          reason:
              'null when untruncated, but the key must exist so "not '
              'truncated" is distinguishable from "not reported"',
        );
      }
    });
  });

  group('ChapterTextLayout for a wrapped paragraph', () {
    testWidgets('highlights every sentence of a wrapped paragraph', (
      tester,
    ) async {
      // The end of the defect this file was written to pin. With spans derived
      // from `debugFragments`, a wrapped paragraph produced no spans at all and
      // nothing could be highlighted; spans now come from the positioned line
      // fragments, so ordinary prose highlights like any other content.
      final box = await pumpHtml(tester, wrappingParagraph);

      final layout = const ChapterTextLayoutBuilder().build(
        hyperBox: box,
        contentHeight: 200,
        viewportHeight: 100,
      );

      expect(layout.hasCharacterMapping, isTrue);
      expect(layout.spans, isNotEmpty);
      expect(
        layout.spans.length,
        greaterThanOrEqualTo(box.debugLines().length),
        reason: 'at least one span per line, since every line has fragments',
      );

      // The whole paragraph is now highlightable, and the character space is
      // the chapter's own, so a range at the end of the text resolves too.
      expect(layout.rectsForCharRange(0, 50), isNotEmpty);
      final last = layout.flowText.trimRight().length;
      expect(layout.rectsForCharRange(last - 10, last), isNotEmpty);
    });

    testWidgets('resolves a sentence to the lines it actually spans', (
      tester,
    ) async {
      // The quality bar: not merely "something is highlighted", but the right
      // thing. A sentence crossing a wrap must resolve to the fragments holding
      // its glyphs, each at its own line's position.
      final box = await pumpHtml(tester, wrappingParagraph);

      final layout = const ChapterTextLayoutBuilder().build(
        hyperBox: box,
        contentHeight: 200,
        viewportHeight: 100,
      );

      final endOfSentence = layout.flowText.indexOf('.') + 1;
      final rects = layout.rectsForCharRange(0, endOfSentence);

      expect(rects, isNotEmpty);
      expect(
        rects.map((r) => r.top).toSet().length,
        greaterThan(1),
        reason:
            'the first sentence wraps, so it must cover more than one line '
            '— a single rect would mean the whole paragraph is being smeared',
      );
    });

    testWidgets('pages start at real character offsets', (tester) async {
      // The latent trap this file also pinned. `buildPages` cannot advance its
      // span cursor when there are no spans, so with the defect present every
      // page claimed to start at the end of the chapter — an internally
      // inconsistent layout that only `hasCharacterMapping` kept contained.
      // Now the first page starts at the chapter's first character and later
      // pages start at genuinely different offsets.
      final box = await pumpHtml(tester, wrappingParagraph);

      final layout = const ChapterTextLayoutBuilder().build(
        hyperBox: box,
        contentHeight: 200,
        viewportHeight: 100,
      );

      expect(layout.pages, isNotEmpty);
      expect(layout.pageStartChars.first, 0);
      expect(
        layout.pageStartChars.every((c) => c <= box.totalCharacterCount),
        isTrue,
      );
      expect(
        layout.pageStartChars.toSet().length,
        greaterThan(1),
        reason:
            'a two-page chapter whose pages both claim to start at the end '
            'is the degenerate layout this test exists to rule out',
      );
    });

    testWidgets('an unwrapped paragraph still builds a usable layout', (
      tester,
    ) async {
      // The control: the whole chain works when the text happens not to wrap,
      // which is why the defect looked like a highlight problem rather than a
      // geometry one. Headings and short list items worked all along.
      final box = await pumpHtml(tester, singleLineParagraph);

      final layout = const ChapterTextLayoutBuilder().build(
        hyperBox: box,
        contentHeight: 200,
        viewportHeight: 100,
      );

      expect(layout.spans, isNotEmpty);
      expect(layout.hasCharacterMapping, isTrue);
      expect(layout.rectsForCharRange(0, 5), isNotEmpty);
    });
  });

  group('a chapter of ordinary prose', () {
    // The gate the earlier stages deferred to. Stage 2 deliberately did not
    // assert that the fragments tile the character space, because
    // `totalCharacterCount` counts text that never reaches a line — hidden
    // elements and replaced content are legitimate holes, and asserting coverage
    // would reject good layouts. Coverage of the text a reader can actually
    // read is a different claim and can be checked, so it is checked here, over
    // a chapter with the things a real one contains.
    const viewportHeight = 600.0;

    Future<ChapterTextLayout> layoutFor(WidgetTester tester) async {
      final box = await pumpHtml(tester, realisticChapter);
      return const ChapterTextLayoutBuilder().build(
        hyperBox: box,
        contentHeight: 2400,
        viewportHeight: viewportHeight,
      );
    }

    testWidgets('is laid out across several pages of spans', (tester) async {
      final layout = await layoutFor(tester);

      expect(layout.hasCharacterMapping, isTrue);
      expect(layout.spans.length, greaterThan(10));
      expect(
        layout.pages.length,
        greaterThan(1),
        reason:
            'a chapter of this length spans pages, and a one-page layout '
            'would mean the pages are being faked',
      );

      // Non-degenerate: the pages start at genuinely different characters, in
      // order, starting at the beginning.
      expect(layout.pageStartChars.first, 0);
      for (var i = 1; i < layout.pageStartChars.length; i++) {
        expect(
          layout.pageStartChars[i],
          greaterThan(layout.pageStartChars[i - 1]),
          reason: 'page $i starts after page ${i - 1}',
        );
      }
      expect(
        layout.pageStartChars.last,
        lessThan(layout.flowText.length),
      );
    });

    testWidgets('every readable character is inside some span', (tester) async {
      // The claim Stage 2 declined to assert, now asserted where it is true.
      //
      // Two kinds of character legitimately have no geometry. Whitespace,
      // because a wrap trims it: the renderer draws no glyph for the space it
      // broke at, and demanding a rect for it would be demanding ink that is
      // not on the page. And the list marker, because the renderer draws it as
      // a marker rather than as a run of text, so there is no fragment for it
      // to come from. Pinning the second kind rather than waving it away is the
      // point: a whole paragraph of prose escaping coverage would still fail.
      final layout = await layoutFor(tester);

      final covered = <int>{};
      for (final span in layout.spans) {
        for (var c = span.charStart; c < span.charEnd; c++) {
          covered.add(c);
        }
      }
      final missing = <int>[];
      for (var i = 0; i < layout.flowText.length; i++) {
        if (layout.flowText[i].trim().isEmpty) continue;
        if (!covered.contains(i)) missing.add(i);
      }

      final unexplained = missing
          .where((i) => layout.flowText[i] != '•')
          .toList();
      expect(
        unexplained,
        isEmpty,
        reason: unexplained.isEmpty
            ? 'only list markers are unplaced'
            : 'characters with no geometry that are not list markers: '
                  '${unexplained.take(12).map((i) {
                    final from = i > 20 ? i - 20 : 0;
                    return '…${layout.flowText.substring(from, i + 20)}…';
                  }).join(' | ')}',
      );

      // And the marker really is there to be excused — three list items, three
      // markers. If the fixture stops containing a list, this says so instead of
      // quietly passing on an empty exception list.
      expect(missing, hasLength(3), reason: 'one marker per list item');
    });

    testWidgets('the real speech text aligns with the real render text', (
      tester,
    ) async {
      // The gate that the rest of this work was missing. Everything above
      // attaches `layout.flowText` as the speech side, which is the easiest
      // possible input: the same string on both sides. Production does not do
      // that. `ReaderBloc` attaches whatever
      // `HtmlTextExtractor.extractSpeechText` produced, and that is a
      // *different* implementation of "strip the HTML" from the tokenizer walk
      // that reconstructs `flowText`. The two disagree — measured on this
      // chapter, 982 characters against 991, first diverging at index 22 where
      // the extractor emits a newline between blocks and the tokenizer emits a
      // space. So this asserts the two-route case, not the one-route case.
      final layout = await layoutFor(tester);
      final speech = HtmlTextExtractor.extractSpeechText(realisticChapter);

      expect(speech, isNot(layout.flowText), reason: 'the fixture premise');

      final coordinator = PaginationCoordinator()
        ..initialize(
          chapterCount: 1,
          viewportHeight: viewportHeight,
          contentHeight: 2400,
        );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: layout);
      final map = coordinator.attachSpeechText(0, speech);
      expect(map, isNotNull);

      // The block boundaries are in gaps, so the map is honest about roughly a
      // character in seven being an approximation rather than an identity. Pinned
      // as a bound, not an exact figure: what matters is that it is nowhere near
      // the "walks forward in step through text with no counterpart" failure,
      // which scores high and is wrong.
      expect(
        map!.exactFraction,
        greaterThan(0.75),
        reason: 'block boundaries cost a bounded amount, not the chapter',
      );

      // The claim that actually matters: every sentence lands on its own text.
      // Compared with whitespace collapsed and a list marker allowed, because
      // both differences are real and both are the map behaving correctly — the
      // speech side breaks a line where the render side breaks a space, and the
      // renderer draws a list marker the speech side never says.
      String normalise(String s) => s
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .replaceFirst(RegExp(r'^[•\-\s]+'), '');

      var start = 0;
      var checked = 0;
      final wrong = <String>[];
      for (var i = 0; i < speech.length; i++) {
        if (speech[i] != '.') continue;
        final end = i + 1;
        if (normalise(speech.substring(start, end)).isEmpty) {
          start = end;
          continue;
        }
        final from = map.renderCharFor(start);
        final to = map.renderCharFor(end - 1);
        final landed = (from >= 0 && to >= from && to < layout.flowText.length)
            ? normalise(layout.flowText.substring(from, to + 1))
            : '<unmapped>';
        final expected = normalise(speech.substring(start, end));
        checked++;
        if (landed != expected && wrong.length < 5) {
          wrong.add('expected "$expected"\n        landed   "$landed"');
        }
        start = end;
      }

      expect(checked, greaterThan(5), reason: 'the fixture has sentences');
      expect(
        wrong,
        isEmpty,
        reason:
            'these sentences landed on the wrong text:\n'
            '${wrong.join('\n')}',
      );
    });

    testWidgets('a sentence in the last paragraph still highlights', (
      tester,
    ) async {
      // The whole chain, on text far from the start of the chapter — where an
      // offset recovered by resynchronisation rather than by identity would
      // have drifted by the time it got here.
      final layout = await layoutFor(tester);

      final coordinator = PaginationCoordinator()
        ..initialize(
          chapterCount: 1,
          viewportHeight: viewportHeight,
          contentHeight: 2400,
        );
      coordinator.registerChapterLayout(chapterIndex: 0, layout: layout);
      final map = coordinator.attachSpeechText(0, layout.flowText)!;

      expect(map.exactFraction, 1.0, reason: 'plain prose places by identity');

      final start = layout.flowText.lastIndexOf('None of that');
      final end = layout.flowText.indexOf('.', start) + 1;
      final rects = coordinator.rectsForSpeechRange(0, start, end);

      expect(rects, isNotEmpty);
      // And it is on a page that exists, rather than past the end of the chapter.
      expect(coordinator.pageForSpeechOffset(0, start), isNotNull);
      expect(
        coordinator.pageForSpeechOffset(0, start),
        lessThan(
          layout.pages.length,
        ),
      );
    });
  });
}
