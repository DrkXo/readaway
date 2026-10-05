import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/tts_lyric_view.dart';
import 'package:readaway/src/features/settings/domain/entity/tts_lyric_style.dart';
import 'package:readaway_core/readaway_core.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../helpers/test_mocks.mocks.dart';

TtsChunk chunkAt(int i, {String? spokenText, String? text}) => TtsChunk(
  id: '0:$i:0',
  sectionIndex: 0,
  sentenceIndex: i,
  text: text ?? 'Sentence number $i.',
  spokenText: spokenText,
  startOffset: i * 20,
  endOffset: i * 20 + 19,
);

TtsTimeline timelineOf(List<double> seconds) =>
    TtsTimeline.fromSeconds(seconds);

/// Loads [lrc] into a controller and hands back the parsed lines.
///
/// Goes through [LyricController] rather than the package's parser directly
/// because that is the path the view takes, and because the barrel does not
/// export the model — `lyricNotifier` is the only way in, which makes this a
/// test of the real contract rather than of an internal.
List<dynamic> parsedLines(
  String lrc, {
  String? translation,
  void Function(LyricController)? then,
}) {
  final controller = LyricController()
    ..loadLyric(lrc, translationLyric: translation);
  then?.call(controller);
  return List<dynamic>.from(controller.lyricNotifier.value?.lines ?? const []);
}

/// The line index a position activates, through the controller.
///
/// This is the whole point of the layer: the app feeds one clock into
/// `setProgress` and the package decides which sentence is active. If the
/// generated timestamps disagree with the axis by anything, this is where it
/// shows.
int activeLineAt(LyricController controller, Duration position) {
  controller.setProgress(position);
  return controller.activeIndexNotifiter.value;
}

void main() {
  group('generated LRC survives the package that will read it', () {
    test('every measured sentence lands on its exact boundary', () {
      final timeline = timelineOf(const [0.4, 1.25, 0.9, 2.0]);
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(4, chunkAt),
      );

      final lines = parsedLines(page.lrc);
      expect(lines, hasLength(4));
      for (var i = 0; i < 4; i++) {
        expect(
          lines[i].start,
          timeline.startOf(i),
          reason: 'sentence $i must land on its measured boundary',
        );
        expect(lines[i].text, 'Sentence number $i.');
      }
    });

    test('always writes three fractional digits', () {
      // `.5` is 500ms to a reader that pads the fraction out and `.05` is
      // 50ms, so the same three characters mean different things by width
      // alone. Fixing the width is what removes the ambiguity.
      final page = buildPageLyric(
        timeline: timelineOf(const [0.4, 0.005, 0.05, 0.5]),
        queue: List.generate(4, chunkAt),
      );
      final timed = page.lrc
          .split('\n')
          .where((l) => l.isNotEmpty)
          .where((l) => !l.startsWith('[ti') && !l.startsWith('[offset'));

      expect(timed, hasLength(4));
      for (final line in timed) {
        expect(
          RegExp(r'^\[\d{2,}:\d{2}\.\d{3}\]').hasMatch(line),
          isTrue,
          reason: 'fraction is not three digits: $line',
        );
      }
    });

    test('recovers sub-second boundaries exactly', () {
      // Boundaries at 405ms and 455ms are the ones a one- or two-digit
      // fraction would get wrong, by a factor of ten or a hundred.
      final timeline = timelineOf(const [0.4, 0.005, 0.05, 0.5]);
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(4, chunkAt),
      );

      final lines = parsedLines(page.lrc);
      expect(
        lines.map((l) => l.start),
        List.generate(4, timeline.startOf),
      );
    });

    test('minutes accumulate past sixty instead of wrapping', () {
      // `[00:75.000]` reads as a quarter past the hour to some consumers and
      // as nonsense to others, so the field is written as a running total.
      final timeline = timelineOf(const [61.0, 14.0, 6.0]);
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(3, chunkAt),
      );

      expect(page.lrc, contains('[01:01.000]'));
      expect(page.lrc, contains('[01:15.000]'));

      final lines = parsedLines(page.lrc);
      expect(
        lines.map((l) => l.start),
        List.generate(3, timeline.startOf),
      );
    });

    test('a sentence spanning several source lines stays one line', () {
      // LRC is newline-delimited. An unescaped newline would split the
      // sentence in two, and the tail would be filed under the next
      // sentence's timestamp.
      final page = buildPageLyric(
        timeline: timelineOf(const [1.0, 1.0]),
        queue: [
          chunkAt(0, text: 'A sentence that\nwrapped across\nthree lines.'),
          chunkAt(1),
        ],
      );

      final lines = parsedLines(page.lrc);
      expect(lines, hasLength(2));
      expect(lines[0].text, 'A sentence that wrapped across three lines.');
      expect(lines[0].start, Duration.zero);
    });

    test('a timestamp written inside a sentence does not fork the line', () {
      // The parser scans the whole line for bracketed times, so a literal one
      // in the prose becomes a second anchor: the line renders twice, once
      // here and once at the timestamp printed in the book.
      final page = buildPageLyric(
        timeline: timelineOf(const [1.0, 1.0]),
        queue: [
          chunkAt(0, text: '[00:45] he sang the chorus twice.'),
          chunkAt(1),
        ],
      );

      final lines = parsedLines(page.lrc);
      expect(lines, hasLength(2));
      expect(lines[0].start, Duration.zero);
      expect(lines[1].start, const Duration(seconds: 1));
    });

    test('the metadata tags are not mistaken for timed lines', () {
      final page = buildPageLyric(
        timeline: timelineOf(const [0.5]),
        queue: [chunkAt(0)],
      );

      late Object? model;
      final lines = parsedLines(
        page.lrc,
        then: (c) {
          model = c.lyricNotifier.value;
        },
      );
      expect(lines, hasLength(1));
      expect(
        (model! as dynamic).idTags['offset'],
        '0',
        reason: 'the offset tag is metadata, not a line',
      );
    });

    test('a long page keeps every boundary to the millisecond', () {
      // A full page is where per-line rounding would accumulate into drift
      // visible by the last sentence.
      final timeline = timelineOf(
        List.generate(300, (i) => 1.337 + i * 0.0111),
      );
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(300, chunkAt),
      );

      final lines = parsedLines(page.lrc);
      expect(lines, hasLength(300));
      for (var i = 0; i < 300; i++) {
        expect(
          lines[i].start.inMilliseconds,
          timeline.startOf(i).inMilliseconds,
          reason: 'drift at sentence $i',
        );
      }
    });

    test('an axis shorter than the queue truncates rather than guessing', () {
      // Synthesis measures sentences in the background, so for the first
      // second of a page the queue is routinely longer than the axis.
      final page = buildPageLyric(
        timeline: timelineOf(const [0.5, 0.5]),
        queue: List.generate(6, chunkAt),
      );

      final lines = parsedLines(page.lrc);
      expect(lines, hasLength(2));
      expect(lines[1].start, const Duration(milliseconds: 500));
    });

    test('an empty axis produces no lines', () {
      final page = buildPageLyric(
        timeline: timelineOf(const []),
        queue: List.generate(3, chunkAt),
      );
      expect(parsedLines(page.lrc), isEmpty);
    });
  });

  group('generated translations', () {
    test('are omitted when nothing is rewritten for speech', () {
      final page = buildPageLyric(
        timeline: timelineOf(const [0.5, 0.5]),
        queue: List.generate(2, chunkAt),
      );
      expect(page.translationLrc, isNull);
    });

    test('carry the synthesized text where it differs', () {
      final page = buildPageLyric(
        timeline: timelineOf(const [0.5, 0.5]),
        queue: [
          chunkAt(0),
          chunkAt(1, spokenText: 'Sentence number 1, rewritten.'),
        ],
      );

      final lines = parsedLines(
        page.lrc,
        translation: page.translationLrc,
      );
      expect(lines[0].translation, isNull);
      expect(lines[1].translation, 'Sentence number 1, rewritten.');
    });

    test('land on their own sentence whichever one needs rewriting', () {
      // A translation is matched to its line by timestamp, and the writer
      // places a line by its position in the list. Dropping the entries that
      // need no translation would therefore slide every rewritten sentence
      // onto its predecessor's boundary — which reads as plausible output and
      // is silently wrong.
      final page = buildPageLyric(
        timeline: timelineOf(const [0.4, 0.6, 1.0]),
        queue: [
          chunkAt(0, spokenText: 'Sentence number 0, spoken differently.'),
          chunkAt(1),
          chunkAt(2, spokenText: 'Sentence number 2, spoken differently.'),
        ],
      );

      final lines = parsedLines(
        page.lrc,
        translation: page.translationLrc,
      );
      expect(
        lines.map((l) => l.translation),
        [
          'Sentence number 0, spoken differently.',
          null,
          'Sentence number 2, spoken differently.',
        ],
      );
    });

    test('line up by timestamp, not by position', () {
      // The parser matches a translation to its line on the exact
      // millisecond, so both halves have to be built from one axis. A
      // sentence that was skipped leaves the halves misaligned otherwise.
      final timeline = timelineOf(const [0.4, 0.6, 1.0]);
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(3, chunkAt),
      );
      final spoken = buildLrc(
        timeline: timeline,
        texts: List.generate(3, (i) => 'Spoken $i.'),
      );

      final lines = parsedLines(page.lrc, translation: spoken);
      expect(
        lines.map((l) => l.translation),
        ['Spoken 0.', 'Spoken 1.', 'Spoken 2.'],
      );
    });
  });

  group('a position activates the sentence the axis says it should', () {
    test('at the start of every sentence', () {
      final timeline = timelineOf(const [0.4, 0.6, 1.0, 0.25]);
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(4, chunkAt),
      );

      final controller = LyricController()..loadLyric(page.lrc);
      addTearDown(controller.dispose);

      for (var i = 0; i < 4; i++) {
        expect(
          activeLineAt(controller, timeline.startOf(i)),
          i,
          reason: 'sentence $i must be active at its own start',
        );
      }
    });

    test('just before the next boundary', () {
      final timeline = timelineOf(const [0.4, 0.6]);
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(2, chunkAt),
      );

      final controller = LyricController()..loadLyric(page.lrc);
      addTearDown(controller.dispose);

      expect(activeLineAt(controller, const Duration(milliseconds: 399)), 0);
      expect(activeLineAt(controller, const Duration(milliseconds: 400)), 1);
      expect(activeLineAt(controller, const Duration(milliseconds: 999)), 1);
    });

    test('for every position on a full page, not just the boundaries', () {
      // The gap baked after each sentence means playback spends real time
      // between boundaries. That gap belongs to the sentence before it, or
      // the highlight blinks off the voice during every pause.
      final timeline = timelineOf(
        List.generate(40, (i) => 0.6 + (i % 7) * 0.15),
      );
      final page = buildPageLyric(
        timeline: timeline,
        queue: List.generate(40, chunkAt),
      );

      final controller = LyricController()..loadLyric(page.lrc);
      addTearDown(controller.dispose);

      for (var i = 0; i < 40; i++) {
        final start = timeline.startOf(i);
        final end = timeline.startOf(i + 1);
        // One millisecond before the next sentence takes over is still this
        // sentence's audio, so this is the last position that must be ours.
        expect(
          activeLineAt(controller, end - const Duration(milliseconds: 1)),
          i,
          reason: 'sentence $i lost the tail of its own audio',
        );
        expect(activeLineAt(controller, start), i);
      }
    });
  });

  group('TtsLyricView', () {
    late MockReaderTtsRepository tts;

    setUp(() {
      tts = MockReaderTtsRepository();
    });

    /// A repository reporting [timeline] over [queue], with every stream the
    /// view subscribes to already at its settled value.
    ///
    /// Only the members this view reads are stubbed. Mockito keeps an
    /// unconsumed argument matcher armed until the next `when`, so a stub for
    /// something a test never exercises — a seek, say — would break the
    /// following stub instead of going quietly unused.
    void given({
      required TtsTimeline? timeline,
      required List<TtsChunk> queue,
    }) {
      when(tts.timeline).thenReturn(timeline);
      when(tts.timelineStream).thenAnswer(
        (_) => BehaviorSubject<TtsTimeline?>.seeded(timeline).stream,
      );
      when(tts.queue).thenReturn(queue);
      when(tts.queueVersion).thenAnswer(
        (_) => BehaviorSubject<int>.seeded(0).stream,
      );
      when(tts.globalPositionStream).thenAnswer(
        (_) => BehaviorSubject<Duration>.seeded(Duration.zero).stream,
      );
    }

    Future<void> pumpView(
      WidgetTester tester, {
      TtsLyricStyle style = const TtsLyricStyle(),
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: TtsLyricView(tts: tts, style: style),
          ),
        ),
      ),
    );

    /// The lines the view handed to the package.
    ///
    /// Read off the controller rather than with `find.text`, because the view
    /// draws through a `CustomPaint` — there is no `Text` widget in the tree to
    /// find, and asserting on painted pixels would test the package's renderer
    /// instead of what this view produced.
    List<dynamic> linesInView(WidgetTester tester) => List<dynamic>.from(
      tester
              .widget<LyricView>(find.byType(LyricView))
              .controller
              .lyricNotifier
              .value
              ?.lines ??
          const [],
    );

    testWidgets('shows a placeholder before anything is measured', (
      tester,
    ) async {
      given(timeline: null, queue: [chunkAt(0)]);
      await pumpView(tester);

      expect(find.byType(LyricView), findsNothing);
      expect(find.text('Preparing sentences…'), findsOneWidget);
    });

    testWidgets('hands the sentences to the lyric view', (tester) async {
      given(
        timeline: timelineOf(const [0.4, 0.6, 1.0]),
        queue: List.generate(3, chunkAt),
      );
      await pumpView(tester);
      await tester.pump();

      expect(find.byType(LyricView), findsOneWidget);
      final lines = linesInView(tester);
      expect(lines.map((l) => l.text), [
        'Sentence number 0.',
        'Sentence number 1.',
        'Sentence number 2.',
      ]);
      expect(lines[1].start, const Duration(milliseconds: 400));
    });

    testWidgets('follows the axis as synthesis measures more sentences', (
      tester,
    ) async {
      final axis = BehaviorSubject<TtsTimeline?>.seeded(
        timelineOf(const [0.4]),
      );
      when(tts.timeline).thenAnswer((_) => axis.value);
      when(tts.timelineStream).thenAnswer((_) => axis.stream);
      when(tts.queue).thenReturn(List.generate(3, chunkAt));
      when(tts.queueVersion).thenAnswer((_) => const Stream<int>.empty());
      when(tts.globalPositionStream).thenAnswer(
        (_) => const Stream<Duration>.empty(),
      );
      addTearDown(axis.close);

      await pumpView(tester);
      await tester.pump();
      expect(linesInView(tester), hasLength(1));

      axis.add(timelineOf(const [0.4, 0.6, 1.0]));
      await tester.pump();

      expect(linesInView(tester), hasLength(3));
    });

    testWidgets('drives the active line from the page-wide position', (
      tester,
    ) async {
      final position = BehaviorSubject<Duration>.seeded(Duration.zero);
      addTearDown(position.close);
      when(tts.timeline).thenReturn(timelineOf(const [0.4, 0.6, 1.0]));
      when(tts.timelineStream).thenAnswer(
        (_) => BehaviorSubject<TtsTimeline?>.seeded(
          timelineOf(const [0.4, 0.6, 1.0]),
        ).stream,
      );
      when(tts.queue).thenReturn(List.generate(3, chunkAt));
      when(tts.queueVersion).thenAnswer((_) => const Stream<int>.empty());
      when(tts.globalPositionStream).thenAnswer((_) => position.stream);

      await pumpView(tester);
      await tester.pump();

      final controller = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;
      expect(controller.activeIndexNotifiter.value, 0);

      position.add(const Duration(milliseconds: 500));
      await tester.pump();
      expect(controller.activeIndexNotifiter.value, 1);

      position.add(const Duration(milliseconds: 1400));
      await tester.pump();
      expect(controller.activeIndexNotifiter.value, 2);
    });
  });

  group("the reader's alignment choices", () {
    late MockReaderTtsRepository tts;

    setUp(() {
      tts = MockReaderTtsRepository();
      when(tts.timeline).thenReturn(timelineOf(const [0.4, 0.6, 1.0]));
      when(tts.timelineStream).thenAnswer(
        (_) => BehaviorSubject<TtsTimeline?>.seeded(
          timelineOf(const [0.4, 0.6, 1.0]),
        ).stream,
      );
      when(tts.queue).thenReturn(List.generate(3, chunkAt));
      when(tts.queueVersion).thenAnswer(
        (_) => BehaviorSubject<int>.seeded(0).stream,
      );
      when(tts.globalPositionStream).thenAnswer(
        (_) => BehaviorSubject<Duration>.seeded(Duration.zero).stream,
      );
    });

    Future<void> pumpWith(
      WidgetTester tester,
      TtsLyricStyle style, {
      bool singleLine = false,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: TtsLyricView(tts: tts, style: style, singleLine: singleLine),
          ),
        ),
      ),
    );

    /// The style the view actually handed the package.
    ///
    /// Falls back the same way the package's own `style` getter does, so this
    /// cannot pass by reading a default the view never set.
    LyricStyle styleInView(WidgetTester tester) =>
        tester.widget<LyricView>(find.byType(LyricView)).style ??
        LyricStyles.default1;

    testWidgets('each choice reaches the package under its own name', (
      tester,
    ) async {
      await pumpWith(
        tester,
        const TtsLyricStyle(
          lineAlign: LyricLineAlign.justify,
          contentAlign: LyricContentAlign.end,
          selectionAnchorAlign: LyricAnchorAlign.start,
          activeAnchorAlign: LyricAnchorAlign.end,
        ),
      );
      await tester.pump();

      final style = styleInView(tester);
      expect(style.lineTextAlign, TextAlign.justify);
      expect(style.contentAlignment, CrossAxisAlignment.end);
      expect(style.selectionAlignment, MainAxisAlignment.start);
      expect(style.activeAlignment, MainAxisAlignment.end);
    });

    testWidgets('leaves the centred look alone until the reader changes it', (
      tester,
    ) async {
      await pumpWith(tester, const TtsLyricStyle());
      await tester.pump();

      final style = styleInView(tester);
      expect(style.lineTextAlign, TextAlign.center);
      expect(style.contentAlignment, CrossAxisAlignment.center);
      expect(style.selectionAlignment, MainAxisAlignment.center);
      expect(style.activeAlignment, MainAxisAlignment.center);
    });

    testWidgets('moves the two anchors independently', (tester) async {
      // The package resolves `activeAlignment` to whatever the *selection*
      // alignment was when the style was built. Handing it one anchor and not
      // the other would therefore retarget the playing line as a side effect
      // of editing the tapped-line anchor, which is a choice nobody made.
      await pumpWith(
        tester,
        const TtsLyricStyle(
          selectionAnchorAlign: LyricAnchorAlign.start,
          activeAnchorAlign: LyricAnchorAlign.center,
        ),
      );
      await tester.pump();

      expect(styleInView(tester).selectionAlignment, MainAxisAlignment.start);
      expect(styleInView(tester).activeAlignment, MainAxisAlignment.center);
    });

    testWidgets('rebuilds the package layout when a choice changes', (
      tester,
    ) async {
      await pumpWith(tester, const TtsLyricStyle());
      await tester.pump();
      final before = tester.state(find.byType(LyricView));
      final controller = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;

      await pumpWith(
        tester,
        const TtsLyricStyle(contentAlign: LyricContentAlign.start),
      );
      await tester.pump();

      // A new state object, because the package sizes each line's painter once
      // and then reuses it: without the remount the new alignment would be
      // paired with painters laid out by the old one.
      expect(tester.state(find.byType(LyricView)), isNot(same(before)));
      expect(styleInView(tester).contentAlignment, CrossAxisAlignment.start);
      // The controller belongs to this widget, not to the package's state, so
      // playback survives the remount.
      expect(
        tester.widget<LyricView>(find.byType(LyricView)).controller,
        same(controller),
      );
    });

    testWidgets('leaves the package alone when the choice is unchanged', (
      tester,
    ) async {
      await pumpWith(tester, const TtsLyricStyle());
      await tester.pump();
      final before = tester.state(find.byType(LyricView));

      await pumpWith(tester, const TtsLyricStyle());
      await tester.pump();

      expect(tester.state(find.byType(LyricView)), same(before));
    });

    testWidgets('single-line mode draws one sentence and takes no touch', (
      tester,
    ) async {
      await pumpWith(tester, const TtsLyricStyle(), singleLine: true);
      await tester.pump();

      final style = styleInView(tester);
      expect(style.activeLineOnly, isTrue);
      // Together, or not at all. Drawing one line while still answering taps on
      // the invisible ones gives the reader targets they cannot see.
      expect(style.disableTouchEvent, isTrue);
    });

    testWidgets('single-line mode is off by default', (tester) async {
      await pumpWith(tester, const TtsLyricStyle());
      await tester.pump();

      final style = styleInView(tester);
      expect(style.activeLineOnly, isFalse);
      expect(style.disableTouchEvent, isFalse);
    });

    testWidgets('a tap in single-line mode reaches no line', (tester) async {
      // The alternative to this is a reader tapping at what they read as a
      // sentence and landing on a different one, with nothing on screen to
      // contradict the result.
      await pumpWith(tester, const TtsLyricStyle(), singleLine: true);
      await tester.pump();

      final controller = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;
      controller.setProgress(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(100, 300));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('switching view keeps the sentence in play', (tester) async {
      // The page is not rebuilt between the two shapes, so a reader who
      // switches while a sentence is halfway through does not lose their place
      // to a change of view.
      await pumpWith(tester, const TtsLyricStyle());
      await tester.pump();
      final before = tester.state(find.byType(LyricView));
      final controller = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;
      controller.setProgress(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      final playing = controller.activeIndexNotifiter.value;
      expect(playing, isNonZero);

      await pumpWith(tester, const TtsLyricStyle(), singleLine: true);
      await tester.pump();

      expect(
        tester.widget<LyricView>(find.byType(LyricView)).controller,
        same(controller),
      );
      expect(tester.state(find.byType(LyricView)), same(before));
      expect(controller.activeIndexNotifiter.value, playing);
    });
  });

  group('tapping a line', () {
    // Mockito cannot invent a value for a sealed `Result`, and it wants one
    // even for a call that is about to be stubbed.
    provideDummy<Result<void>>(const Success<void>(null));

    // Five sentences, so a tap landing on the wrong line cannot be mistaken
    // for a tap landing on the right one.
    final timeline = timelineOf(const [0.4, 0.6, 1.0, 0.5, 0.8]);
    late List<TtsChunk> queue;
    late MockReaderTtsRepository tts;
    late List<int> seeks;

    setUp(() {
      queue = List.generate(5, chunkAt);
      tts = MockReaderTtsRepository();
      seeks = [];

      when(tts.timeline).thenReturn(timeline);
      when(tts.timelineStream).thenAnswer(
        (_) => BehaviorSubject<TtsTimeline?>.seeded(timeline).stream,
      );
      when(tts.queue).thenReturn(queue);
      when(tts.queueVersion).thenAnswer(
        (_) => BehaviorSubject<int>.seeded(0).stream,
      );
      when(tts.globalPositionStream).thenAnswer(
        (_) => BehaviorSubject<Duration>.seeded(Duration.zero).stream,
      );
      when(tts.seekToChunk(any)).thenAnswer((inv) async {
        seeks.add(inv.positionalArguments.first as int);
        return const Success(null);
      });
    });

    /// Pumps the view with [position] fed to the controller, so the highlight
    /// and the hit rects have settled before anything is tapped.
    Future<LyricController> pumpAt(
      WidgetTester tester,
      Duration position, {
      double height = 600,
      TtsLyricStyle style = const TtsLyricStyle(),
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: height,
              child: TtsLyricView(tts: tts, style: style),
            ),
          ),
        ),
      );
      final controller = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;
      controller.setProgress(position);
      await tester.pumpAndSettle();
      return controller;
    }

    /// The rects the package hit-tests a tap against, keyed by line index.
    ///
    /// Read straight off the state rather than inferred by tapping: a tap arms
    /// the package's resume debounce, which scrolls the list on a later pump
    /// and silently invalidates any rect measured after it.
    Map<int, Rect> hitRects(WidgetTester tester) {
      final state = tester.state(find.byType(LyricView));
      return (state as dynamic).showLineRects as Map<int, Rect>;
    }

    testWidgets('tapping a line seeks that exact sentence', (tester) async {
      await pumpAt(tester, Duration.zero);

      final size = tester.getSize(find.byType(LyricView));
      final rects = hitRects(tester);
      expect(rects, isNotEmpty, reason: 'lines must be tappable at all');

      // Tap the middle of each line's own rect and require that same sentence.
      // The rect key is the layout index, and `lines[key].start` is what the
      // callback hands the view, so a disagreement anywhere in that chain — the
      // rects, the parser, or the index lookup — lands here.
      for (final entry in rects.entries) {
        final centre = entry.value.center;
        seeks.clear();
        await tester.tapAt(Offset(size.width / 2, centre.dy));
        await tester.pump();

        expect(
          seeks,
          [entry.key],
          reason:
              'the line drawn at y=${centre.dy} is sentence ${entry.key}, '
              'and tapping it must seek to ${entry.key}',
        );
      }
    });

    testWidgets('every sentence is reachable, in order, top to bottom', (
      tester,
    ) async {
      // Short viewport, so this covers what an anchor-based check cannot: a
      // page taller than the space it is drawn in.
      await pumpAt(tester, Duration.zero, height: 200);

      final rects = hitRects(tester);
      final keys = rects.keys.toList()..sort();

      expect(keys, isNotEmpty);
      expect(
        keys.first,
        0,
        reason: 'the top of the list is the first sentence',
      );

      // Down the screen means up the list, and every line must sit strictly
      // below the one before it. A shifted, duplicated or reordered rect
      // breaks this, and that is exactly the class of bug a tap reports as
      // "it played the wrong one".
      for (var i = 1; i < keys.length; i++) {
        expect(
          rects[keys[i]]!.top,
          greaterThan(rects[keys[i - 1]]!.bottom),
          reason: 'sentence ${keys[i]} must be drawn below ${keys[i - 1]}',
        );
      }

      for (final key in keys) {
        seeks.clear();
        await tester.tapAt(Offset(100, rects[key]!.center.dy));
        await tester.pump();
        expect(seeks, [key]);
      }
    });

    testWidgets('the first sentence is pinned to the top, not the anchor', (
      tester,
    ) async {
      await pumpAt(tester, Duration.zero);

      // The anchor would put sentence 0 a third of the way down, but there is
      // nothing above it to scroll, so it stays at the top. This is what makes
      // a page read from the top rather than starting mid-screen.
      final first = hitRects(tester)[0]!;
      expect(
        first.top,
        closeTo(24, 1),
        reason: 'sentence 0 sits just below the top edge',
      );

      seeks.clear();
      await tester.tapAt(Offset(200, first.center.dy));
      await tester.pump();
      expect(seeks, [0]);
    });
  });
}
