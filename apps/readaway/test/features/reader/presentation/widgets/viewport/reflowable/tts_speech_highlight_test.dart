import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart'
    show HyperViewer, RenderHyperBox;
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/chapter_text_layout_builder.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/tts_speech_highlight.dart';
import 'package:readaway_core/readaway_core.dart';

/// The painted result of a highlight, read back as pixels.
///
/// Asserting on rendered output rather than on recorded draw calls keeps the
/// tests tied to what the reader actually sees, which is the thing the placement
/// and clipping rules exist to get right.
class _Painted {
  _Painted(this._data, this.width, this.height);

  final ByteData _data;
  final int width;
  final int height;

  bool _hasInk(int x, int y) {
    final i = (y * width + x) * 4;
    return _data.getUint8(i + 3) > 0;
  }

  /// Whether any pixel in [y] was painted.
  bool rowPainted(int y) {
    for (var x = 0; x < width; x++) {
      if (_hasInk(x, y)) return true;
    }
    return false;
  }

  /// The first and last painted rows, or null when nothing was painted.
  (int, int)? get paintedRows {
    int? first;
    var last = -1;
    for (var y = 0; y < height; y++) {
      if (rowPainted(y)) {
        first ??= y;
        last = y;
      }
    }
    if (first == null) return null;
    return (first, last);
  }

  /// The leftmost and rightmost painted columns within [y].
  (int, int)? spanAt(int y) {
    int? left;
    var right = -1;
    for (var x = 0; x < width; x++) {
      if (_hasInk(x, y)) {
        left ??= x;
        right = x;
      }
    }
    if (left == null) return null;
    return (left, right);
  }

  Color? colourAt(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      _data.getUint8(i + 3),
      _data.getUint8(i),
      _data.getUint8(i + 1),
      _data.getUint8(i + 2),
    );
  }

  /// The horizontal extent of the ink on each row that has any, keyed by row.
  ///
  /// Rounded corners leave the first and last row of a box a little narrower
  /// than the rest, so this is only comparable across rows when the painter was
  /// asked for square corners.
  Map<int, int> rowWidths() {
    final widths = <int, int>{};
    for (var y = 0; y < height; y++) {
      final span = spanAt(y);
      if (span == null) continue;
      widths[y] = span.$2 + 1;
    }
    return widths;
  }
}

Future<_Painted> _render(
  TtsSpeechHighlightPainter painter, {
  Size size = const Size(400, 1000),
}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return _Painted(data!, size.width.toInt(), size.height.toInt());
}

/// [_render] for use inside a widget test.
///
/// Rasterising an image is real asynchronous work on the engine's own schedule,
/// which a widget test's fake clock never advances — awaiting it in the test
/// body deadlocks. [WidgetTester.runAsync] steps outside the fake-async zone so
/// the image can actually arrive.
Future<_Painted> _renderInTest(
  WidgetTester tester,
  TtsSpeechHighlightPainter painter, {
  Size size = const Size(400, 1000),
}) async {
  final painted = await tester.runAsync(() => _render(painter, size: size));
  expect(painted, isNotNull, reason: 'runAsync returned nothing to assert on');
  return painted!;
}

TtsSpeechHighlightPainter _painter({
  required List<Rect> rects,
  List<Rect>? wordRects,
  double sliceTop = 0,
  Color color = const Color(0xFF0000FF),
  Color? wordColor,
  TtsHighlightStyle style = TtsHighlightStyle.highlight,
  double cornerRadius = 3,
}) => TtsSpeechHighlightPainter(
  rects: rects,
  wordRects: wordRects,
  sliceTop: sliceTop,
  color: color,
  wordColor: wordColor,
  style: style,
  cornerRadius: cornerRadius,
);

/// Walks a render subtree for the [RenderHyperBox] holding the laid-out chapter,
/// the same way `ReflowableVirtualPage` finds it.
RenderHyperBox? _findHyperBox(RenderObject? root) {
  if (root == null) return null;
  if (root is RenderHyperBox) return root;
  RenderHyperBox? found;
  root.visitChildren((child) => found ??= _findHyperBox(child));
  return found;
}

/// Three sentences in one paragraph, which wraps several times at 300 units.
const multiSentenceParagraph =
    '<p>The quick brown fox jumps over the lazy dog. While the reader turns '
    'another page of a long chapter, nobody pauses to consider what any of it '
    'was for in the first place. The dog, for its part, keeps running.</p>';

void main() {
  group('placement', () {
    test('draws a chapter-local rect at its offset within the page', () async {
      // The page starts 1000 units into the chapter, and the rect sits at 1100,
      // so it must appear 100 units down the visible page.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 1100, 400, 20)], sliceTop: 1000),
      );

      expect(painted.paintedRows, (100, 119));
      expect(painted.spanAt(110), (0, 399));
    });

    test('draws nothing for a rect belonging to another page', () async {
      // Viewing the second page while the spoken range is on the first.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 10, 400, 20)], sliceTop: 1000),
      );

      expect(painted.paintedRows, isNull);
    });

    test('draws one box per line of a multi-line range', () async {
      final painted = await _render(
        _painter(
          rects: [
            Rect.fromLTWH(0, 1000, 400, 20),
            Rect.fromLTWH(0, 1024, 400, 20),
            Rect.fromLTWH(0, 1048, 400, 20),
          ],
          sliceTop: 1000,
        ),
      );

      // Three 20-unit lines separated by 4-unit gaps: rows 0-19, 24-43, 48-67.
      expect(painted.rowPainted(19), isTrue);
      expect(painted.rowPainted(22), isFalse);
      expect(painted.rowPainted(24), isTrue);
      expect(painted.rowPainted(43), isTrue);
      expect(painted.rowPainted(47), isFalse);
      expect(painted.rowPainted(48), isTrue);
      expect(painted.paintedRows, (0, 67));
    });

    test('draws nothing for an empty range', () async {
      expect((await _render(_painter(rects: const []))).paintedRows, isNull);
    });
  });

  group('clipping at page boundaries', () {
    test('clips a range that starts on the previous page', () async {
      // The rect runs 960-1040 and the page starts at 1000, so only its lower
      // 40 units are on screen.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 960, 400, 80)], sliceTop: 1000),
      );

      expect(painted.paintedRows, (0, 39));
    });

    test('clips a range that continues onto the next page', () async {
      // The rect runs 1980-2180, so on a page starting at 1000 only the first
      // 20 units sit above the page's lower edge.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 1980, 400, 200)], sliceTop: 1000),
      );

      expect(painted.paintedRows, (980, 999));
    });

    test('skips the lines of a range that span many pages', () async {
      // Forty lines spread over more than one page. The off-screen ones must
      // not be drawn: they would be invisible anyway, and a range this long
      // should not cost a draw call per line.
      final painted = await _render(
        _painter(
          rects: List.generate(
            40,
            (i) => Rect.fromLTWH(0, 1000 + (i * 24), 400, 20),
          ),
          sliceTop: 1000,
        ),
      );

      final rows = painted.paintedRows;
      expect(rows, isNotNull);
      expect(rows!.$2, lessThan(1000));
      expect(rows.$1, 0);
    });
  });

  group('appearance', () {
    test('uses the requested colour', () async {
      final painted = await _render(
        _painter(
          rects: const [Rect.fromLTWH(0, 0, 400, 20)],
          color: const Color(0xFFFF0000),
        ),
        size: const Size(400, 100),
      );

      expect(painted.colourAt(200, 10), const Color(0xFFFF0000));
    });

    test('rounds the corners of a highlighted line', () async {
      final painted = await _render(
        _painter(
          rects: const [Rect.fromLTWH(0, 0, 400, 20)],
          cornerRadius: 12,
        ),
        size: const Size(400, 100),
      );

      // With a corner radius the very corner pixel stays unpainted, which a
      // square box would have filled.
      expect(painted.rowPainted(0) && painted.spanAt(0) != null, isTrue);
      expect(painted.spanAt(0)!.$1, greaterThan(0));
    });
  });

  group('a sentence inside a wrapped paragraph', () {
    // Stage 4, end to end: real HTML through the renderer, through the layout
    // builder, through the coordinator's speech map, into the painter, and read
    // back as pixels. Every stage below has its own tests; what this group adds
    // is that the chain does not lose the sentence on the way through, which is
    // what the original defect did — a wrapped paragraph produced no spans at
    // all, so no sentence in it could be highlighted anywhere.

    /// The layout and coordinator for [multiSentenceParagraph], laid out at the
    /// same size production uses: a 300-unit column and a page a hundred units
    /// tall, which puts the paragraph on three pages.
    Future<
      ({
        PaginationCoordinator coordinator,
        ChapterTextLayout layout,
      })
    >
    pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: HyperViewer(html: multiSentenceParagraph),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = _findHyperBox(
        find.byType(HyperViewer).evaluate().first.renderObject,
      );
      expect(box, isNotNull, reason: 'HyperViewer produced no RenderHyperBox');

      final layout = const ChapterTextLayoutBuilder().build(
        hyperBox: box!,
        contentHeight: 200,
        viewportHeight: 100,
      );
      final coordinator = PaginationCoordinator()
        ..initialize(chapterCount: 1, viewportHeight: 100, contentHeight: 200);
      coordinator.registerChapterLayout(chapterIndex: 0, layout: layout);
      // The speech side is the flow text here, so the sentence offsets below are
      // guaranteed to be the right ones and this group is left testing only what
      // it claims to: that a range becomes per-line runs, at the renderer's own
      // widths, clipped at each page edge. The two-route case — production's
      // `HtmlTextExtractor` output against the tokenizer's `flowText`, which
      // disagree at block boundaries — is gated separately in
      // `render_hyper_box_geometry_test.dart`, where it is the whole subject.
      coordinator.attachSpeechText(0, layout.flowText);

      return (coordinator: coordinator, layout: layout);
    }

    /// The speech offsets of the sentences in [layout], as `(start, end)` pairs.
    List<(int, int)> sentences(ChapterTextLayout layout) {
      final stops = <int>[];
      for (var i = 0; i < layout.flowText.length; i++) {
        if (layout.flowText[i] == '.') stops.add(i + 1);
      }
      var start = 0;
      return stops.map((stop) {
        final sentence = (start, stop);
        start = stop;
        return sentence;
      }).toList();
    }

    testWidgets('paints the lines one sentence covers, and no others', (
      tester,
    ) async {
      final (coordinator: coordinator, layout: layout) = await pump(tester);
      final (start, end) = sentences(layout).first;

      final sentence = coordinator.rectsForSpeechRange(0, start, end);
      final whole = coordinator.rectsForSpeechRange(
        0,
        0,
        layout.flowText.length,
      );

      expect(sentence, isNotEmpty);
      expect(
        sentence.length,
        lessThan(whole.length),
        reason: 'a sentence is a strict subset of the paragraph it is in',
      );
      // One rect per line the sentence covers, each at that line's own height.
      expect(
        sentence.map((r) => r.top).toSet().length,
        sentence.length,
        reason: 'a run per line, not one box smeared over several',
      );

      final painted = await _renderInTest(
        tester,
        _painter(rects: sentence),
        size: const Size(400, 224),
      );

      // The sentence stops well short of the paragraph's last line, which is
      // the difference between reading along with the speaker and smearing the
      // whole paragraph on as soon as it starts.
      final sentenceRows = painted.paintedRows!;
      final paragraph = await _renderInTest(
        tester,
        _painter(rects: whole),
        size: const Size(400, 224),
      );
      expect(paragraph.paintedRows!.$2, greaterThan(sentenceRows.$2));
    });

    testWidgets('each line is painted at its own width', (tester) async {
      // The runs are the renderer's measured lines, not a box drawn to the
      // column width: a line that ends early shows it. Without real geometry
      // there is nothing to end early, which is why this is worth asserting.
      //
      // Square corners, so the row widths are the rect widths and the two sets
      // can be compared exactly — a rounded corner would make the first and last
      // row of every run a little narrower than the run itself.
      final (coordinator: coordinator, layout: layout) = await pump(tester);
      final (start, end) = sentences(layout).first;

      final rects = coordinator.rectsForSpeechRange(0, start, end);
      final painted = await _renderInTest(
        tester,
        _painter(
          rects: rects,
          cornerRadius: 0,
          color: const Color(0xFF0000FF),
        ),
        size: const Size(400, 224),
      );

      final rectWidths = rects.map((r) => r.width.round()).toSet();
      expect(rectWidths.length, greaterThan(1), reason: 'the fixture premise');
      expect(
        painted.rowWidths().values.toSet(),
        rectWidths,
        reason: 'every painted width is a measured line and every one appears',
      );
    });

    testWidgets('a sentence crossing a page break paints on neither page twice', (
      tester,
    ) async {
      final (coordinator: coordinator, layout: layout) = await pump(tester);
      final offsets = coordinator.getChapterPageOffsets(0);
      final boundary = layout.pageStartChars[1];

      // The sentence holding the page boundary: it starts on the first page and
      // ends on the second, so its runs have to be split between them.
      final crossing = sentences(layout).firstWhere(
        (s) => s.$1 < boundary && s.$2 > boundary,
        orElse: () => fail('no sentence crosses the page boundary'),
      );

      final rects = coordinator.rectsForSpeechRange(
        0,
        crossing.$1,
        crossing.$2,
      );
      expect(rects.length, greaterThan(1));

      // Each page draws only the runs it can see, at the height it has them.
      final first = await _renderInTest(
        tester,
        _painter(rects: rects, sliceTop: offsets[0]),
        size: const Size(400, 96),
      );
      final second = await _renderInTest(
        tester,
        _painter(rects: rects, sliceTop: offsets[1]),
        size: const Size(400, 96),
      );

      // The first page starts the sentence mid-column and runs out of page
      // before it finishes it.
      expect(first.paintedRows!.$1, greaterThan(0));
      expect(
        first.paintedRows!.$2,
        95,
        reason: 'clipped at the page edge rather than drawn past it',
      );
      // The second picks it up from its own top edge.
      expect(second.paintedRows!.$1, 0);
      expect(second.paintedRows!.$2, lessThan(95));

      // And neither page paints the whole sentence: the two bands are disjoint
      // in chapter coordinates, and together they are not the whole range.
      final firstSpan = first.spanAt(first.paintedRows!.$2)!;
      final secondSpan = second.spanAt(second.paintedRows!.$2)!;
      expect(firstSpan, isNot(secondSpan));
    });
  });

  group('shouldRepaint', () {
    List<Rect> rects() => [const Rect.fromLTWH(0, 10, 400, 20)];

    test('is false for an identical delegate', () {
      expect(
        _painter(rects: rects()).shouldRepaint(_painter(rects: rects())),
        isFalse,
      );
    });

    test('is true when the range moves', () {
      expect(
        _painter(rects: rects()).shouldRepaint(
          _painter(rects: [const Rect.fromLTWH(0, 30, 400, 20)]),
        ),
        isTrue,
      );
    });

    test('is true when the range changes length', () {
      expect(
        _painter(rects: rects()).shouldRepaint(
          _painter(
            rects: const [
              Rect.fromLTWH(0, 10, 400, 20),
              Rect.fromLTWH(0, 30, 400, 20),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('is true when the page offset changes', () {
      // A page turn reuses the painter with a different slice, so the same
      // range lands somewhere else and must repaint.
      expect(
        _painter(rects: rects(), sliceTop: 0).shouldRepaint(
          _painter(rects: rects(), sliceTop: 1000),
        ),
        isTrue,
      );
    });

    test('is true when the colour changes', () {
      expect(
        _painter(
          rects: rects(),
          color: const Color(0xFF0000FF),
        ).shouldRepaint(
          _painter(rects: rects(), color: const Color(0xFFFF0000)),
        ),
        isTrue,
      );
    });

    test('is true when wordRects changes', () {
      expect(
        _painter(
          rects: rects(),
          wordRects: const [Rect.fromLTWH(10, 10, 50, 20)],
        ).shouldRepaint(
          _painter(
            rects: rects(),
            wordRects: const [Rect.fromLTWH(70, 10, 50, 20)],
          ),
        ),
        isTrue,
      );

      expect(
        _painter(
          rects: rects(),
          wordRects: const [Rect.fromLTWH(10, 10, 50, 20)],
        ).shouldRepaint(
          _painter(rects: rects(), wordRects: null),
        ),
        isTrue,
      );
    });

    test('is true when highlight style changes', () {
      expect(
        _painter(
          rects: rects(),
          style: TtsHighlightStyle.highlight,
        ).shouldRepaint(
          _painter(
            rects: rects(),
            style: TtsHighlightStyle.underline,
          ),
        ),
        isTrue,
      );
    });
  });

  group('dual-focus karaoke word highlighting and styles', () {
    testWidgets('paints both sentence and active word rects', (tester) async {
      const sentenceRect = Rect.fromLTWH(0, 10, 200, 30);
      const wordRect = Rect.fromLTWH(50, 10, 60, 30);

      final painted = await _renderInTest(
        tester,
        _painter(
          rects: const [sentenceRect],
          wordRects: const [wordRect],
          color: const Color(0x330000FF),
          wordColor: const Color(0x880000FF),
          cornerRadius: 0,
        ),
        size: const Size(300, 100),
      );

      // Verify that the sentence region is painted
      expect(painted.rowPainted(20), isTrue);

      // Verify that pixel inside the word has higher alpha than pixel outside
      final sentencePixel = painted.colourAt(10, 20);
      final wordPixel = painted.colourAt(70, 20);
      expect(sentencePixel, isNotNull);
      expect(wordPixel, isNotNull);
      expect(wordPixel!.a, greaterThan(sentencePixel!.a));
    });

    testWidgets('renders underline style', (tester) async {
      const sentenceRect = Rect.fromLTWH(0, 10, 200, 30);

      final painted = await _renderInTest(
        tester,
        _painter(
          rects: const [sentenceRect],
          style: TtsHighlightStyle.underline,
          color: const Color(0xFF0000FF),
        ),
        size: const Size(300, 100),
      );

      // Underline should be painted at the bottom of the rect (y around 39)
      expect(painted.rowPainted(39), isTrue);
      // But the middle of the rect (y=20) should not be filled
      expect(painted.rowPainted(20), isFalse);
    });

    testWidgets('renders squiggly style', (tester) async {
      const sentenceRect = Rect.fromLTWH(0, 10, 200, 30);

      final painted = await _renderInTest(
        tester,
        _painter(
          rects: const [sentenceRect],
          style: TtsHighlightStyle.squiggly,
          color: const Color(0xFF0000FF),
        ),
        size: const Size(300, 100),
      );

      // Squiggly line should be painted near the bottom
      expect(
        painted.rowPainted(38) ||
            painted.rowPainted(39) ||
            painted.rowPainted(40),
        isTrue,
      );
      // And the middle of the rect should not be filled
      expect(painted.rowPainted(20), isFalse);
    });

    testWidgets('renders outline style', (tester) async {
      const sentenceRect = Rect.fromLTWH(10, 10, 100, 40);

      final painted = await _renderInTest(
        tester,
        _painter(
          rects: const [sentenceRect],
          style: TtsHighlightStyle.outline,
          color: const Color(0xFF0000FF),
          cornerRadius: 0,
        ),
        size: const Size(200, 100),
      );

      // Border should be painted along the top and bottom
      expect(painted.rowPainted(10), isTrue);
      expect(painted.rowPainted(50), isTrue);
      // The interior (e.g. y=30, x=50) should be hollow
      final centerPixel = painted.colourAt(50, 30);
      expect(centerPixel?.a ?? 0, 0);
    });
  });
}
