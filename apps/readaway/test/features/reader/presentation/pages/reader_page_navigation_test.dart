import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/services/wakelock_service.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_tts_repository.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/tts/reader_tts_bloc.dart';
import 'package:readaway/src/features/reader/presentation/pages/reader_page.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'package:readaway_core/readaway_core.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_mocks.dart';

class _MockReaderBloc extends MockBloc<ReaderEvent, ReaderState>
    implements ReaderBloc {
  final List<ReaderEvent> addedEvents = [];

  @override
  void add(ReaderEvent event) {
    addedEvents.add(event);
    super.add(event);
  }

  @override
  bool get isClosed => false;
}

class _MockReaderTtsBloc extends MockBloc<ReaderTtsEvent, ReaderTtsState>
    implements ReaderTtsBloc {
  @override
  bool get isClosed => false;
}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {
  @override
  bool get isClosed => false;
}

class _MockAnnotationsBloc extends MockBloc<AnnotationsEvent, AnnotationsState>
    implements AnnotationsBloc {
  @override
  bool get isClosed => false;
}

ChapterTextLayout _createLayout({
  required int startChar,
  required int endChar,
  required double contentHeight,
  required List<PageSlice> pages,
}) {
  final length = endChar - startChar;
  final text = 'A' * length;
  return ChapterTextLayout(
    contentHeight: contentHeight,
    viewportHeight: 1000,
    lineBounds: const [],
    spans: [
      TextSpanBox(
        charStart: startChar,
        charEnd: endChar,
        rect: Rect.fromLTWH(0, 0, 400, contentHeight),
        nodeTag: 'p',
        type: 'text',
      ),
    ],
    pages: pages,
    flowText: text,
    totalCharacterCount: length,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late _MockReaderBloc readerBloc;
  late _MockReaderTtsBloc ttsBloc;
  late _MockSettingsBloc settingsBloc;
  late _MockAnnotationsBloc annotationsBloc;
  late MockReaderRepository readerRepository;
  late MockReaderTtsRepository ttsRepository;
  late PaginationCoordinator coordinator;
  late WakelockService wakelock;

  setUp(() {
    GetIt.I.reset();

    readerBloc = _MockReaderBloc();
    ttsBloc = _MockReaderTtsBloc();
    settingsBloc = _MockSettingsBloc();
    annotationsBloc = _MockAnnotationsBloc();
    readerRepository = MockReaderRepository();
    ttsRepository = MockReaderTtsRepository();
    coordinator = PaginationCoordinator();
    wakelock = WakelockService();

    final timeline = BehaviorSubject<TtsTimeline?>.seeded(null);
    when(ttsRepository.timelineStream).thenAnswer((_) => timeline);

    GetIt.I.registerSingleton<ReaderRepository>(readerRepository);
    GetIt.I.registerSingleton<ReaderTtsRepository>(ttsRepository);
    GetIt.I.registerSingleton<PaginationCoordinator>(coordinator);
    GetIt.I.registerSingleton<WakelockService>(wakelock);
  });

  tearDown(() {
    coordinator.dispose();
    GetIt.I.reset();
  });

  Widget createHarness({
    required ReaderState readerState,
    required SettingsState settingsState,
  }) {
    whenListen(
      readerBloc,
      const Stream<ReaderState>.empty(),
      initialState: readerState,
    );
    whenListen(
      ttsBloc,
      const Stream<ReaderTtsState>.empty(),
      initialState: const ReaderTtsState(),
    );
    whenListen(
      settingsBloc,
      const Stream<SettingsState>.empty(),
      initialState: settingsState,
    );
    whenListen(
      annotationsBloc,
      const Stream<AnnotationsState>.empty(),
      initialState: const AnnotationsState(),
    );

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ReaderBloc>.value(value: readerBloc),
          BlocProvider<ReaderTtsBloc>.value(value: ttsBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<AnnotationsBloc>.value(value: annotationsBloc),
        ],
        child: const ReaderPage(
          initialPath: '/books/test.epub',
        ),
      ),
    );
  }

  testWidgets(
    'jumpToNote navigates directly to exact virtual page when chapter is already measured',
    (
      tester,
    ) async {
      const readerState = ReaderState(
        loading: true,
        documentPath: '/books/test.epub',
        isReflowable: true,
        pageCount: 2,
        currentPage: 0,
        currentVirtualPage: 0,
      );

      const settingsState = SettingsState(
        globalReaderPrefs: ReaderPreferences(
          scrollDirection: ReaderScrollDirection.horizontal,
          pageSnap: true,
        ),
      );

      await tester.pumpWidget(
        createHarness(readerState: readerState, settingsState: settingsState),
      );
      await tester.pump();

      // 2 chapters:
      // Chapter 0: 2 pages (global 0, 1)
      // Chapter 1: 3 pages (global 2, 3, 4)
      coordinator.initialize(
        chapterCount: 2,
        viewportHeight: 1000,
        contentHeight: 2000,
      );

      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _createLayout(
          startChar: 0,
          endChar: 500,
          contentHeight: 2000,
          pages: const [
            PageSlice(
              index: 0,
              startY: 0,
              endY: 1000,
              startChar: 0,
              endChar: 250,
            ),
            PageSlice(
              index: 1,
              startY: 1000,
              endY: 2000,
              startChar: 250,
              endChar: 500,
            ),
          ],
        ),
      );

      coordinator.registerChapterLayout(
        chapterIndex: 1,
        layout: _createLayout(
          startChar: 0,
          endChar: 750,
          contentHeight: 3000,
          pages: const [
            PageSlice(
              index: 0,
              startY: 0,
              endY: 1000,
              startChar: 0,
              endChar: 250,
            ),
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
        ),
      );

      final dynamic state = tester.state(find.byType(ReaderPage));

      // Note at startChar 350 in chapter 1 (which falls on page 1 of chapter 1)
      // Global page = getGlobalPageForChapter(1) + 1 = 2 + 1 = 3.
      final note = ReaderNote(
        id: 'n1',
        type: ReaderNoteType.highlight,
        anchor: const ReaderNoteAnchor(
          kind: NoteAnchorKind.reflowable,
          chapterIndex: 1,
          startChar: 350,
          endChar: 400,
          text: 'target highlight',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state.jumpToNote(note);
      await tester.pump();

      final expectedPage = coordinator.globalPageForChar(1, 350);
      expect(state.viewportController.currentPage, equals(expectedPage));
      expect(expectedPage, equals(3));
    },
  );

  testWidgets(
    'jumpToNote jumps provisionally and refines to exact page when chapter measures',
    (
      tester,
    ) async {
      const readerState = ReaderState(
        loading: true,
        documentPath: '/books/test.epub',
        isReflowable: true,
        pageCount: 2,
        currentPage: 0,
        currentVirtualPage: 0,
      );

      const settingsState = SettingsState(
        globalReaderPrefs: ReaderPreferences(
          scrollDirection: ReaderScrollDirection.horizontal,
          pageSnap: true,
        ),
      );

      await tester.pumpWidget(
        createHarness(readerState: readerState, settingsState: settingsState),
      );
      await tester.pump();

      // Chapter 0 measured (2 pages: 0, 1)
      // Chapter 1 unmeasured (placeholder page 2)
      coordinator.initialize(
        chapterCount: 2,
        viewportHeight: 1000,
        contentHeight: 2000,
      );

      coordinator.registerChapterLayout(
        chapterIndex: 0,
        layout: _createLayout(
          startChar: 0,
          endChar: 500,
          contentHeight: 2000,
          pages: const [
            PageSlice(
              index: 0,
              startY: 0,
              endY: 1000,
              startChar: 0,
              endChar: 250,
            ),
            PageSlice(
              index: 1,
              startY: 1000,
              endY: 2000,
              startChar: 250,
              endChar: 500,
            ),
          ],
        ),
      );

      expect(coordinator.isChapterMeasured(1), isFalse);

      final dynamic state = tester.state(find.byType(ReaderPage));

      final note = ReaderNote(
        id: 'n1',
        type: ReaderNoteType.bookmark,
        anchor: const ReaderNoteAnchor(
          kind: NoteAnchorKind.reflowable,
          chapterIndex: 1,
          startChar: 600,
          endChar: 600,
          text: 'bookmark in ch1',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provisionalExpected = coordinator.getGlobalPageForChapter(1);
      expect(provisionalExpected, equals(2));

      // Initial jump to unmeasured chapter 1
      state.jumpToNote(note);
      await tester.pump();

      // Provisional jump to chapter 1's start page (page 2)
      expect(state.viewportController.currentPage, equals(2));
      expect(
        readerBloc.addedEvents,
        contains(const ReaderEvent.loadPage(index: 1)),
      );

      // Now Chapter 1 finishes loading and layout measurement completes!
      coordinator.registerChapterLayout(
        chapterIndex: 1,
        layout: _createLayout(
          startChar: 0,
          endChar: 750,
          contentHeight: 3000,
          pages: const [
            PageSlice(
              index: 0,
              startY: 0,
              endY: 1000,
              startChar: 0,
              endChar: 250,
            ),
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
        ),
      );

      await tester.pump();

      // char 600 falls on slice 2 (page 2 of chapter 1 -> global page 2 + 2 = 4)
      final refinedExpected = coordinator.globalPageForChar(1, 600);
      expect(refinedExpected, equals(4));
      expect(state.viewportController.currentPage, equals(4));
    },
  );

  testWidgets(
    'jumpToNote and jumpToChapter in continuous mode navigate directly by chapter index',
    (
      tester,
    ) async {
      const readerState = ReaderState(
        documentPath: '/books/test.epub',
        isReflowable: true,
        pageCount: 5,
        currentPage: 0,
      );

      // Continuous scroll prefs
      const settingsState = SettingsState(
        globalReaderPrefs: ReaderPreferences(
          scrollDirection: ReaderScrollDirection.vertical,
          pageSnap: false,
        ),
      );

      await tester.pumpWidget(
        createHarness(readerState: readerState, settingsState: settingsState),
      );
      await tester.pump();

      final dynamic state = tester.state(find.byType(ReaderPage));

      // Jump to chapter 3 directly
      state.jumpToChapter(3);
      await tester.pump();
      expect(state.viewportController.currentPage, equals(3));

      // Jump to note in chapter 2 in continuous mode
      final note = ReaderNote(
        id: 'n2',
        type: ReaderNoteType.highlight,
        anchor: const ReaderNoteAnchor(
          kind: NoteAnchorKind.reflowable,
          chapterIndex: 2,
          startChar: 100,
          endChar: 200,
          text: 'text in ch2',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state.jumpToNote(note);
      await tester.pump();
      expect(state.viewportController.currentPage, equals(2));
    },
  );
}
