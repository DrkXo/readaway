import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/toc/reader_side_panel.dart';

import '../../../../../helpers/test_mocks.dart';

const _path = '/books/a.epub';
final _at = DateTime(2026, 1, 1);

ReaderNote _bookmark() => ReaderNote(
  id: 'b1',
  type: ReaderNoteType.bookmark,
  anchor: const ReaderNoteAnchor(
    kind: NoteAnchorKind.page,
    chapterIndex: 3,
    pageIndex: 3,
    text: 'Saved place',
  ),
  createdAt: _at,
  updatedAt: _at,
);

ReaderNote _highlight() => ReaderNote(
  id: 'h1',
  type: ReaderNoteType.highlight,
  anchor: const ReaderNoteAnchor(
    chapterIndex: 2,
    startChar: 0,
    endChar: 9,
    text: 'a passage',
  ),
  createdAt: _at,
  updatedAt: _at,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late MockAnnotationsRepository repository;

  setUp(() {
    repository = MockAnnotationsRepository();
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
          notes: [_bookmark(), _highlight()],
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

  /// Hosts the panel on a tab that is not Contents.
  ///
  /// The Contents tab builds [ReaderTocContent], which reads the reader bloc;
  /// starting elsewhere keeps this a test of the tab bar and the two lists
  /// rather than of the table of contents.
  Future<void> pumpPanel(
    WidgetTester tester,
    AnnotationsBloc bloc, {
    ReaderSidePanelTab tab = ReaderSidePanelTab.bookmarks,
  }) async {
    await tester.pumpWidget(
      BlocProvider<AnnotationsBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(
            body: ReaderSidePanel(
              onJumpToChapter: (_) {},
              onJumpToNote: (_) {},
              initialTab: tab,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('names every tab and opens on the requested one', (tester) async {
    final bloc = await loadedBloc();

    await pumpPanel(tester, bloc);

    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('Bookmarks'), findsOneWidget);
    expect(find.text('Annotations'), findsOneWidget);
    // The open tab's content, and only it.
    expect(find.text('Saved place'), findsOneWidget);
    expect(find.text('a passage'), findsNothing);
  });

  testWidgets('switching tabs swaps the view', (tester) async {
    final bloc = await loadedBloc();
    await pumpPanel(tester, bloc);

    await tester.tap(find.text('Annotations'));
    await tester.pumpAndSettle();

    expect(find.text('a passage'), findsOneWidget);
    expect(find.text('Saved place'), findsNothing);

    await tester.tap(find.text('Bookmarks'));
    await tester.pumpAndSettle();

    expect(find.text('Saved place'), findsOneWidget);
  });

  testWidgets('each row still reports the note it stands for', (tester) async {
    final bloc = await loadedBloc();
    ReaderNote? tapped;

    await tester.pumpWidget(
      BlocProvider<AnnotationsBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(
            body: ReaderSidePanel(
              onJumpToChapter: (_) {},
              onJumpToNote: (note) => tapped = note,
              initialTab: ReaderSidePanelTab.annotations,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('a passage'));
    await tester.pump();

    expect(tapped?.id, 'h1');
  });
}
