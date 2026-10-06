import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/annotations/presentation/widgets/notes/reader_annotations_list.dart';
import 'package:readaway/src/features/annotations/presentation/widgets/notes/reader_bookmarks_list.dart';

import '../../../../../helpers/test_mocks.dart';

const _path = '/books/a.epub';
final _at = DateTime(2026, 1, 1);

ReaderNote _bookmark({String id = 'b1', int pageIndex = 3}) => ReaderNote(
  id: id,
  type: ReaderNoteType.bookmark,
  anchor: ReaderNoteAnchor(
    kind: NoteAnchorKind.page,
    chapterIndex: pageIndex,
    pageIndex: pageIndex,
    text: 'Saved place',
  ),
  createdAt: _at,
  updatedAt: _at,
);

ReaderNote _highlight({
  String id = 'h1',
  String excerpt = 'a passage',
  String note = '',
  HighlightStyle style = HighlightStyle.highlight,
  int chapterIndex = 2,
  int colorValueHash = 0,
}) => ReaderNote(
  id: id,
  type: ReaderNoteType.highlight,
  anchor: ReaderNoteAnchor(
    chapterIndex: chapterIndex,
    startChar: 0,
    endChar: excerpt.length,
    text: excerpt,
  ),
  style: style,
  note: note,
  colorValue: colorValueHash == 0 ? 'amber' : 'sky',
  createdAt: _at,
  updatedAt: _at,
);

/// A text note: anchored but not painted.
ReaderNote _textNote({String id = 'n1', String note = 'why it matters'}) =>
    ReaderNote(
      id: id,
      type: ReaderNoteType.note,
      anchor: const ReaderNoteAnchor(
        chapterIndex: 5,
        startChar: 0,
        endChar: 7,
        text: 'a quote',
      ),
      note: note,
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

  Future<AnnotationsBloc> loadedBloc(List<ReaderNote> notes) async {
    when(repository.getForDocument(_path)).thenAnswer((_) async {
      final Result<DocumentNotes> result = Success(
        DocumentNotes(
          documentPath: _path,
          schemaVersion: kDocumentNotesSchemaVersion,
          notes: notes,
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

  Widget host(AnnotationsBloc bloc, Widget child) =>
      BlocProvider<AnnotationsBloc>.value(
        value: bloc,
        child: MaterialApp(home: Scaffold(body: child)),
      );

  group('ReaderBookmarksList', () {
    testWidgets('explains itself when there are no bookmarks', (tester) async {
      final bloc = await loadedBloc(const []);

      await tester.pumpWidget(
        host(bloc, ReaderBookmarksList(onJumpToNote: (_) {})),
      );

      expect(find.text('No bookmarks'), findsOneWidget);
    });

    testWidgets('lists a bookmark with the place it saved', (tester) async {
      final bloc = await loadedBloc([_bookmark(pageIndex: 3)]);

      await tester.pumpWidget(
        host(bloc, ReaderBookmarksList(onJumpToNote: (_) {})),
      );

      expect(find.text('Saved place'), findsOneWidget);
      expect(find.text('Page 4'), findsOneWidget);
    });

    testWidgets('does not list highlights', (tester) async {
      final bloc = await loadedBloc([_bookmark(), _highlight()]);

      await tester.pumpWidget(
        host(bloc, ReaderBookmarksList(onJumpToNote: (_) {})),
      );

      expect(find.text('Saved place'), findsOneWidget);
      expect(find.text('a passage'), findsNothing);
    });

    testWidgets('reports the bookmark the reader taps', (tester) async {
      final bloc = await loadedBloc([_bookmark()]);
      ReaderNote? tapped;

      await tester.pumpWidget(
        host(
          bloc,
          ReaderBookmarksList(onJumpToNote: (note) => tapped = note),
        ),
      );
      await tester.tap(find.text('Saved place'));
      await tester.pump();

      expect(tapped?.id, 'b1');
    });
  });

  group('ReaderAnnotationsList', () {
    testWidgets('explains itself when there are no annotations', (
      tester,
    ) async {
      final bloc = await loadedBloc([_bookmark()]);

      await tester.pumpWidget(
        host(bloc, ReaderAnnotationsList(onJumpToNote: (_) {})),
      );

      expect(find.text('No highlights yet'), findsOneWidget);
    });

    testWidgets('names the style so the row does not rely on colour', (
      tester,
    ) async {
      final bloc = await loadedBloc([
        _highlight(excerpt: 'first', style: HighlightStyle.underline),
        _highlight(
          id: 'h2',
          excerpt: 'second',
          style: HighlightStyle.squiggly,
          colorValueHash: 1,
        ),
      ]);

      await tester.pumpWidget(
        host(bloc, ReaderAnnotationsList(onJumpToNote: (_) {})),
      );

      expect(find.text('Underline · Chapter 3'), findsOneWidget);
      expect(find.text('Squiggly · Chapter 3'), findsOneWidget);
    });

    testWidgets('shows a note body and calls an unpainted record a Note', (
      tester,
    ) async {
      final bloc = await loadedBloc([
        _highlight(note: 'worth quoting'),
        _textNote(note: 'a private thought'),
      ]);

      await tester.pumpWidget(
        host(bloc, ReaderAnnotationsList(onJumpToNote: (_) {})),
      );

      expect(find.text('worth quoting'), findsOneWidget);
      expect(find.text('a private thought'), findsOneWidget);
      expect(find.text('Note · Chapter 6'), findsOneWidget);
    });

    testWidgets('leaves bookmarks to the bookmarks tab', (tester) async {
      final bloc = await loadedBloc([_bookmark(), _highlight()]);

      await tester.pumpWidget(
        host(bloc, ReaderAnnotationsList(onJumpToNote: (_) {})),
      );

      expect(find.text('a passage'), findsOneWidget);
      expect(find.text('Saved place'), findsNothing);
    });

    testWidgets('reports the annotation the reader taps', (tester) async {
      final bloc = await loadedBloc([_highlight(excerpt: 'tap me')]);
      ReaderNote? tapped;

      await tester.pumpWidget(
        host(
          bloc,
          ReaderAnnotationsList(onJumpToNote: (note) => tapped = note),
        ),
      );
      await tester.tap(find.text('tap me'));
      await tester.pump();

      expect(tapped?.id, 'h1');
    });

    testWidgets('search narrows the list, and clearing restores it', (
      tester,
    ) async {
      final bloc = await loadedBloc([
        _highlight(excerpt: 'alpha'),
        _highlight(id: 'h2', excerpt: 'beta'),
      ]);

      await tester.pumpWidget(
        host(bloc, ReaderAnnotationsList(onJumpToNote: (_) {})),
      );

      // The search field carries the query as its own text, so row assertions
      // are scoped to the list instead of matching the field.
      Finder row(String text) => find.descendant(
        of: find.byType(ListView),
        matching: find.text(text),
      );

      final field = find.byKey(const ValueKey('annotations-search-field'));
      await tester.enterText(field, 'alpha');
      await tester.pumpAndSettle();

      expect(row('alpha'), findsOneWidget);
      expect(row('beta'), findsNothing);

      await tester.enterText(field, 'nothing matches this');
      await tester.pumpAndSettle();

      // Filtered down to nothing is not the same as nothing annotated, and it
      // says so while offering the way back.
      expect(find.text('Nothing matches'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(row('alpha'), findsOneWidget);
      expect(row('beta'), findsOneWidget);
    });
  });
}
