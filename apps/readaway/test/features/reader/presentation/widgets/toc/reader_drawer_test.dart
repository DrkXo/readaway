import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/toc/reader_drawer.dart';

import '../../../../../helpers/test_mocks.dart';

class MockReaderBloc extends MockBloc<ReaderEvent, ReaderState>
    implements ReaderBloc {}

const _path = '/books/metro.epub';
final _at = DateTime(2026, 1, 1);

ReaderNote _sampleBookmark() => ReaderNote(
  id: 'b1',
  type: ReaderNoteType.bookmark,
  anchor: const ReaderNoteAnchor(
    kind: NoteAnchorKind.page,
    chapterIndex: 0,
    pageIndex: 0,
    text: 'Chapter One Intro',
  ),
  createdAt: _at,
  updatedAt: _at,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late MockAnnotationsRepository repository;
  late MockReaderBloc readerBloc;

  setUp(() {
    repository = MockAnnotationsRepository();
    readerBloc = MockReaderBloc();
    whenListen(
      readerBloc,
      const Stream<ReaderState>.empty(),
      initialState: const ReaderState(
        bookTitle: 'Test Book',
        outline: [],
        currentPage: 0,
        pageCount: 10,
      ),
    );
    when(repository.save(any)).thenAnswer((invocation) async {
      final Result<DocumentNotes> result = Success(
        invocation.positionalArguments.first as DocumentNotes,
      );
      return result;
    });
  });

  Future<AnnotationsBloc> loadedBloc() async {
    when(repository.getForDocument(_path)).thenAnswer((_) async {
      final Result<DocumentNotes> result = Success(
        DocumentNotes(
          documentPath: _path,
          schemaVersion: kDocumentNotesSchemaVersion,
          notes: [_sampleBookmark()],
          updatedAt: _at,
        ),
      );
      return result;
    });

    final bloc = AnnotationsBloc(repository);
    addTearDown(bloc.close);
    final ready = bloc.stream
        .firstWhere((state) => state.status == AnnotationsStatus.ready)
        .timeout(const Duration(seconds: 5));
    bloc.add(const AnnotationsEvent.loadForDocument(documentPath: _path));
    await ready;
    return bloc;
  }

  Widget buildHarness({
    required Widget child,
    required AnnotationsBloc annotationsBloc,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AnnotationsBloc>.value(value: annotationsBloc),
        BlocProvider<ReaderBloc>.value(value: readerBloc),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            VsCodeThemeExtension(
              MetroColorScheme.kanagawaDragon.toVsCodeTheme(),
            ),
          ],
        ),
        home: child,
      ),
    );
  }

  group('ReaderDrawer Metro UI', () {
    testWidgets('renders flat Metro Drawer with MetroPivot and close button', (
      tester,
    ) async {
      final bloc = await loadedBloc();
      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        buildHarness(
          annotationsBloc: bloc,
          child: Scaffold(
            key: scaffoldKey,
            drawer: ReaderDrawer(
              onJumpToPage: (_) {},
              onJumpToNote: (_) {},
            ),
            body: const Center(child: Text('Reader Body')),
          ),
        ),
      );

      // Open drawer
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byType(MetroPivot), findsOneWidget);
      expect(find.byType(MetroDrawerCloseButton), findsOneWidget);
      expect(find.text('contents'), findsWidgets);
      expect(find.text('bookmarks'), findsOneWidget);
      expect(find.text('annotations'), findsOneWidget);
      expect(find.text('close'), findsOneWidget);

      final drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(drawer.elevation, 0);
      expect(
        drawer.shape,
        const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      );
    });

    testWidgets('tapping close button dismisses the drawer', (tester) async {
      final bloc = await loadedBloc();
      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        buildHarness(
          annotationsBloc: bloc,
          child: Scaffold(
            key: scaffoldKey,
            drawer: ReaderDrawer(
              onJumpToPage: (_) {},
              onJumpToNote: (_) {},
            ),
            body: const Center(child: Text('Reader Body')),
          ),
        ),
      );

      // Open drawer
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);

      // Tap close
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets(
      'tapping note in bookmarks tab triggers jump and dismisses drawer',
      (
        tester,
      ) async {
        final bloc = await loadedBloc();
        final scaffoldKey = GlobalKey<ScaffoldState>();
        ReaderNote? jumpedNote;

        await tester.pumpWidget(
          buildHarness(
            annotationsBloc: bloc,
            child: Scaffold(
              key: scaffoldKey,
              drawer: ReaderDrawer(
                onJumpToPage: (_) {},
                onJumpToNote: (note) => jumpedNote = note,
              ),
              body: const Center(child: Text('Reader Body')),
            ),
          ),
        );

        // Open drawer
        scaffoldKey.currentState?.openDrawer();
        await tester.pumpAndSettle();

        // Switch to bookmarks
        await tester.tap(find.text('bookmarks'));
        await tester.pumpAndSettle();

        expect(find.text('Chapter One Intro'), findsOneWidget);

        // Tap note
        await tester.tap(find.text('Chapter One Intro'));
        await tester.pumpAndSettle();

        expect(jumpedNote?.id, 'b1');
        expect(find.byType(Drawer), findsNothing);
      },
    );
  });
}
