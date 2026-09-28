import 'dart:async';
import 'dart:ui' show Rect;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../helpers/test_mocks.dart';

/// One chapter measured as three pages of 250 characters each.
///
/// The flow text is spelled out at the front so the matcher can tell the
/// rendered marker apart from the text it precedes; a run of identical
/// characters would be indistinguishable from its neighbours.
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

PaginationCoordinator _coordinatorWithLayout({String? flowText}) {
  final coordinator = PaginationCoordinator();
  coordinator.initialize(
    chapterCount: 1,
    viewportHeight: 1000,
    contentHeight: 3000,
  );
  coordinator.registerChapterLayout(
    chapterIndex: 0,
    layout: _layout(flowText: flowText),
  );
  return coordinator;
}

void main() {
  setUpAll(registerMockitoDummies);

  late MockReaderRepository mockReader;
  late MockReaderTtsRepository mockTts;

  setUp(() {
    mockReader = MockReaderRepository();
    mockTts = MockReaderTtsRepository();

    when(mockTts.playbackState).thenAnswer((_) => const Stream.empty());
    when(mockTts.currentChunk).thenAnswer((_) => const Stream.empty());
    when(mockTts.currentVoice).thenReturn(null);
    when(mockTts.availableVoices).thenReturn([]);
    when(mockTts.start()).thenAnswer((_) async {});
    when(
      mockTts.releaseResources(),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  void registerCoordinator(PaginationCoordinator coordinator) {
    GetIt.I.registerSingleton<PaginationCoordinator>(coordinator);
  }

  ReaderBloc buildBloc() => ReaderBloc(
    readerRepository: mockReader,
    ttsRepository: mockTts,
  );

  /// Drives playback through the real chunk stream rather than the event.
  ///
  /// The bloc subscribes to [MockReaderTtsRepository.currentChunk] once, at
  /// construction. A controller hands the bloc nothing, every handler stays
  /// perfectly correct, and no page ever turns, so the wiring is what these
  /// tests exist to cover.
  late StreamController<TtsChunk> chunks;

  blocTest<ReaderBloc, ReaderState>(
    'follows the page as chunks arrive on the speech stream',
    setUp: () {
      chunks = StreamController<TtsChunk>();
      when(mockTts.currentChunk).thenAnswer((_) => chunks.stream);
    },
    build: () {
      final coordinator = _coordinatorWithLayout();
      coordinator.attachSpeechText(0, 'x' * 750);
      registerCoordinator(coordinator);
      return buildBloc();
    },
    seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
    act: (bloc) async {
      // A chunk inside page 0, then one inside page 2. The reader is on a
      // different page throughout, so this is following rather than agreement.
      chunks.add(
        TtsChunk(id: 'a', text: 'a', startOffset: 10, endOffset: 40),
      );
      await Future<void>.delayed(Duration.zero);
      chunks.add(
        TtsChunk(id: 'b', text: 'b', startOffset: 600, endOffset: 640),
      );
      await Future<void>.delayed(Duration.zero);
    },
    tearDown: () => chunks.close(),
    expect: () => [
      isA<ReaderState>()
          .having((s) => s.ttsTargetVirtualPage, 'target', 0)
          .having((s) => s.ttsSpeechRange, 'range', (start: 10, end: 40)),
      isA<ReaderState>()
          .having((s) => s.ttsTargetVirtualPage, 'target', 2)
          .having((s) => s.ttsSpeechRange, 'range', (start: 600, end: 640)),
    ],
  );

  test('ignores chunks that arrive before a chapter is known', () async {
    final coordinator = _coordinatorWithLayout();
    coordinator.attachSpeechText(0, 'x' * 750);
    registerCoordinator(coordinator);

    final chunks = StreamController<TtsChunk>();
    when(mockTts.currentChunk).thenAnswer((_) => chunks.stream);

    final bloc = buildBloc();
    // Playback has not started, so there is no chapter to resolve against. The
    // chunker always reports section 0, so trusting it would silently point the
    // reader at the first chapter of the book.
    chunks.add(
      TtsChunk(id: 'a', text: 'a', startOffset: 600, endOffset: 640),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.ttsTargetVirtualPage, isNull);
    expect(bloc.state.ttsSpeechRange, isNull);

    await chunks.close();
    await bloc.close();
  });

  group('following the spoken text', () {
    // These dispatch the event directly. The tests below cover the wiring that
    // decides whether that event is ever dispatched at all.
    blocTest<ReaderBloc, ReaderState>(
      'resolves a chunk offset to the page holding that text',
      build: () {
        final coordinator = _coordinatorWithLayout();
        coordinator.attachSpeechText(0, 'x' * 750);
        registerCoordinator(coordinator);
        return buildBloc();
      },
      seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) => bloc.add(
        const ReaderEvent.ttsChunkAdvanced(
          chapterIndex: 0,
          startOffset: 300,
          endOffset: 360,
        ),
      ),
      expect: () => [
        isA<ReaderState>()
            .having((s) => s.ttsTargetVirtualPage, 'target page', 1)
            .having((s) => s.ttsSpeechRange, 'range', (start: 300, end: 360)),
      ],
    );

    blocTest<ReaderBloc, ReaderState>(
      'keeps the target on the same page while the chunk advances within it',
      build: () {
        final coordinator = _coordinatorWithLayout();
        coordinator.attachSpeechText(0, 'x' * 750);
        registerCoordinator(coordinator);
        return buildBloc();
      },
      seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) async {
        bloc.add(
          const ReaderEvent.ttsChunkAdvanced(
            chapterIndex: 0,
            startOffset: 10,
            endOffset: 40,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ReaderEvent.ttsChunkAdvanced(
            chapterIndex: 0,
            startOffset: 60,
            endOffset: 90,
          ),
        );
      },
      expect: () => [
        isA<ReaderState>().having((s) => s.ttsTargetVirtualPage, 'target', 0),
        isA<ReaderState>().having((s) => s.ttsTargetVirtualPage, 'target', 0),
      ],
    );

    blocTest<ReaderBloc, ReaderState>(
      'moves the target when the speech crosses a page boundary',
      build: () {
        final coordinator = _coordinatorWithLayout();
        coordinator.attachSpeechText(0, 'x' * 750);
        registerCoordinator(coordinator);
        return buildBloc();
      },
      seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) async {
        bloc.add(
          const ReaderEvent.ttsChunkAdvanced(
            chapterIndex: 0,
            startOffset: 10,
            endOffset: 40,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ReaderEvent.ttsChunkAdvanced(
            chapterIndex: 0,
            startOffset: 600,
            endOffset: 640,
          ),
        );
      },
      expect: () => [
        isA<ReaderState>().having((s) => s.ttsTargetVirtualPage, 'target', 0),
        isA<ReaderState>().having((s) => s.ttsTargetVirtualPage, 'target', 2),
      ],
    );

    blocTest<ReaderBloc, ReaderState>(
      'accounts for text the renderer draws but never speaks',
      build: () {
        // A list marker occupies six characters the speech side skips, so a
        // naive one-to-one mapping would place chunk 245 on page 0 when the
        // text is actually on page 1.
        final coordinator = _coordinatorWithLayout(
          flowText: 'MARKER${'x' * 750}',
        );
        coordinator.attachSpeechText(0, 'x' * 750);
        registerCoordinator(coordinator);
        return buildBloc();
      },
      seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) => bloc.add(
        const ReaderEvent.ttsChunkAdvanced(
          chapterIndex: 0,
          startOffset: 245,
          endOffset: 260,
        ),
      ),
      expect: () => [
        isA<ReaderState>().having((s) => s.ttsTargetVirtualPage, 'target', 1),
      ],
    );
  });

  group('when the chapter cannot be followed', () {
    blocTest<ReaderBloc, ReaderState>(
      'stays put before the speech text has been aligned',
      build: () {
        // Measured, but no speech text attached: nothing to align against.
        registerCoordinator(_coordinatorWithLayout());
        return buildBloc();
      },
      seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) => bloc.add(
        const ReaderEvent.ttsChunkAdvanced(
          chapterIndex: 0,
          startOffset: 300,
          endOffset: 360,
        ),
      ),
      expect: () => <ReaderState>[],
    );

    blocTest<ReaderBloc, ReaderState>(
      'stays put when no coordinator is registered at all',
      build: buildBloc,
      seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) => bloc.add(
        const ReaderEvent.ttsChunkAdvanced(
          chapterIndex: 0,
          startOffset: 300,
          endOffset: 360,
        ),
      ),
      expect: () => <ReaderState>[],
    );

    blocTest<ReaderBloc, ReaderState>(
      'stays put for a chapter that was never measured',
      build: () {
        final coordinator = _coordinatorWithLayout();
        coordinator.attachSpeechText(0, 'x' * 750);
        registerCoordinator(coordinator);
        return buildBloc();
      },
      seed: () => const ReaderState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) => bloc.add(
        const ReaderEvent.ttsChunkAdvanced(
          chapterIndex: 7,
          startOffset: 300,
          endOffset: 360,
        ),
      ),
      expect: () => <ReaderState>[],
    );
  });

  group('clearing the follow state', () {
    blocTest<ReaderBloc, ReaderState>(
      'drops the target and highlight when playback stops',
      build: () {
        final coordinator = _coordinatorWithLayout();
        coordinator.attachSpeechText(0, 'x' * 750);
        registerCoordinator(coordinator);
        return buildBloc();
      },
      seed: () => const ReaderState(
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsTargetVirtualPage: 2,
        ttsSpeechRange: (start: 600, end: 640),
      ),
      act: (bloc) => bloc.add(const ReaderEvent.ttsClose()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.ttsTargetVirtualPage, isNull);
        expect(bloc.state.ttsSpeechRange, isNull);
      },
    );
  });

  group('jumping back to the audio', () {
    blocTest<ReaderBloc, ReaderState>(
      'lands on the page the speech was last placed on',
      build: () {
        final coordinator = _coordinatorWithLayout();
        coordinator.attachSpeechText(0, 'x' * 750);
        registerCoordinator(coordinator);
        return buildBloc();
      },
      seed: () => const ReaderState(
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsTargetVirtualPage: 2,
        currentVirtualPage: 5,
        currentPage: 1,
        pageCount: 3,
      ),
      act: (bloc) => bloc.add(const ReaderEvent.jumpToTtsPage()),
      verify: (bloc) {
        // Not the start of the chapter: the reader who looked ahead wants the
        // passage being read, which is on the chapter's third page.
        expect(bloc.state.currentVirtualPage, 2);
        expect(bloc.state.currentPage, 0);
        // The target is dropped so the viewport applies the reader's own page
        // once, rather than re-applying a target it has just reached.
        expect(bloc.state.ttsTargetVirtualPage, isNull);
      },
    );

    blocTest<ReaderBloc, ReaderState>(
      'keeps the reader on the chapter when nothing has been placed',
      build: () {
        registerCoordinator(_coordinatorWithLayout());
        return buildBloc();
      },
      seed: () => const ReaderState(
        ttsActive: true,
        ttsCurrentPage: 0,
        currentVirtualPage: 5,
        currentPage: 1,
        pageCount: 3,
      ),
      act: (bloc) => bloc.add(const ReaderEvent.jumpToTtsPage()),
      verify: (bloc) {
        expect(bloc.state.currentPage, 0);
        // A null follow page means the chapter was never measured. It must not
        // be mistaken for the reader having no page.
        expect(bloc.state.currentVirtualPage, 5);
      },
    );

    blocTest<ReaderBloc, ReaderState>(
      'does nothing when playback is not on a chapter',
      build: buildBloc,
      seed: () => const ReaderState(currentPage: 4, pageCount: 6),
      act: (bloc) => bloc.add(const ReaderEvent.jumpToTtsPage()),
      expect: () => <ReaderState>[],
    );

    blocTest<ReaderBloc, ReaderState>(
      'does nothing for a chapter outside the document',
      build: buildBloc,
      seed: () => const ReaderState(
        ttsActive: true,
        ttsCurrentPage: 9,
        pageCount: 3,
      ),
      act: (bloc) => bloc.add(const ReaderEvent.jumpToTtsPage()),
      expect: () => <ReaderState>[],
    );
  });

  group('ReaderState derived values', () {
    test('canJumpToTtsPage compares pages once the speech is placed', () {
      // On the right chapter but the wrong page: a chapter-only comparison
      // would call this "already there" and hide the shortcut.
      const wrongPage = ReaderState(
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsTargetVirtualPage: 2,
        currentVirtualPage: 7,
        currentPage: 0,
      );
      expect(wrongPage.canJumpToTtsPage, isTrue);

      const rightPage = ReaderState(
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsTargetVirtualPage: 2,
        currentVirtualPage: 2,
        currentPage: 0,
      );
      expect(rightPage.canJumpToTtsPage, isFalse);
    });

    test('canJumpToTtsPage falls back to chapters when nothing is placed', () {
      // A document with no character mapping still needs the shortcut.
      expect(
        const ReaderState(
          ttsActive: true,
          ttsCurrentPage: 0,
          currentVirtualPage: 3,
          currentPage: 1,
        ).canJumpToTtsPage,
        isTrue,
      );
      expect(
        const ReaderState(
          ttsActive: true,
          ttsCurrentPage: 1,
          currentPage: 1,
        ).canJumpToTtsPage,
        isFalse,
      );
      expect(
        const ReaderState(
          ttsActive: true,
          ttsCurrentPage: 0,
          currentPage: 0,
        ).canJumpToTtsPage,
        isFalse,
      );
      // Nothing playing means nothing to jump back to.
      expect(
        const ReaderState(ttsCurrentPage: 0, currentPage: 3).canJumpToTtsPage,
        isFalse,
      );
    });

    test('ttsPageLabel shows the placed page, or the chapter without one', () {
      // One-based, and agreeing with the page indicator, which shows
      // currentVirtualPage in a reflowable document.
      expect(
        const ReaderState(
          ttsActive: true,
          ttsCurrentPage: 3,
          ttsTargetVirtualPage: 7,
        ).ttsPageLabel,
        8,
      );
      expect(
        const ReaderState(ttsActive: true, ttsCurrentPage: 3).ttsPageLabel,
        4,
      );
      expect(const ReaderState().ttsPageLabel, isNull);
    });

    test('hasTtsHighlight requires active playback and a range', () {
      const reading = ReaderState(
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsSpeechRange: (start: 0, end: 10),
      );
      expect(reading.hasTtsHighlight, isTrue);

      // A range left over from playback that has stopped must not highlight.
      expect(
        const ReaderState(
          ttsCurrentPage: 0,
          ttsSpeechRange: (start: 0, end: 10),
        ).hasTtsHighlight,
        isFalse,
      );
      expect(
        const ReaderState(ttsActive: true, ttsCurrentPage: 0).hasTtsHighlight,
        isFalse,
      );
    });
  });
}
