import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/annotations/presentation/widgets/notes/reader_note_editor_sheet.dart';

import '../../../../../helpers/test_mocks.dart';

const _path = '/books/a.epub';
final _at = DateTime(2026, 1, 1);

const _anchor = ReaderNoteAnchor(
  chapterIndex: 2,
  startChar: 0,
  endChar: 5,
  text: 'hello',
);

ReaderNote _textNote({String note = 'first draft'}) => ReaderNote(
  id: 'n1',
  type: ReaderNoteType.note,
  anchor: _anchor,
  note: note,
  createdAt: _at,
  updatedAt: _at,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late MockAnnotationsRepository repository;
  final field = find.byKey(const ValueKey('note-editor-field'));

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

  /// Opens the sheet as a pushed route, so its Save and Delete can pop.
  ///
  /// The route transition is pumped by hand rather than settled: the field
  /// takes focus and its cursor blink would keep [WidgetTester.pumpAndSettle]
  /// from ever settling.
  Future<void> pumpSheet(
    WidgetTester tester,
    AnnotationsBloc bloc, {
    ReaderNote? note,
  }) async {
    await tester.pumpWidget(
      BlocProvider<AnnotationsBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: ReaderNoteEditorSheet(
                          anchor: note?.anchor ?? _anchor,
                          note: note,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Taps [label] and waits for the bloc to reach [until].
  ///
  /// The subscription starts before the tap, because the bloc's stream does not
  /// replay the state it is already in.
  Future<void> tapAndWait(
    WidgetTester tester,
    String label,
    AnnotationsBloc bloc,
    bool Function(AnnotationsState state) until,
  ) async {
    final reached = bloc.stream
        .firstWhere(until)
        .timeout(const Duration(seconds: 5));

    await tester.tap(find.text(label));
    await tester.pump();
    await reached;
    await tester.pump();
  }

  testWidgets('saves a new note from what was typed', (tester) async {
    final bloc = await loadedBloc(const []);
    await pumpSheet(tester, bloc);

    await tester.enterText(field, 'worth quoting');
    await tester.pump();
    await tapAndWait(
      tester,
      'Save',
      bloc,
      (state) => state.notes.any((note) => note.note == 'worth quoting'),
    );

    final note = bloc.state.notes.single;
    expect(note.type, ReaderNoteType.note);
    expect(note.note, 'worth quoting');
    // Attached to the passage the selection covered.
    expect(note.anchor.text, 'hello');
  });

  testWidgets('a new note with nothing typed is not saved', (tester) async {
    final bloc = await loadedBloc(const []);
    await pumpSheet(tester, bloc);

    await tester.enterText(field, '   ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(bloc.state.notes, isEmpty);
  });

  testWidgets('opens on the existing body and rewrites it', (tester) async {
    final note = _textNote();
    final bloc = await loadedBloc([note]);
    await pumpSheet(tester, bloc, note: note);

    expect(find.text('first draft'), findsOneWidget);

    await tester.enterText(field, 'second draft');
    await tester.pump();
    await tapAndWait(
      tester,
      'Save',
      bloc,
      (state) => state.notes.single.note == 'second draft',
    );

    expect(bloc.state.notes.single.id, note.id);
  });

  testWidgets('clearing the body of a note drops the record', (tester) async {
    final note = _textNote();
    final bloc = await loadedBloc([note]);
    await pumpSheet(tester, bloc, note: note);

    await tester.enterText(field, '');
    await tester.pump();
    await tapAndWait(
      tester,
      'Save',
      bloc,
      (state) => state.notes.single.isDeleted,
    );

    expect(bloc.state.notes.single.isDeleted, isTrue);
  });

  testWidgets('deleting does not also write the edited body', (tester) async {
    final note = _textNote();
    final bloc = await loadedBloc([note]);
    await pumpSheet(tester, bloc, note: note);

    await tester.enterText(field, 'typed then deleted');
    await tester.pump();
    await tapAndWait(
      tester,
      'Delete',
      bloc,
      (state) => state.notes.single.isDeleted,
    );

    // Delete means delete: the abandoned edit is not saved alongside it.
    expect(bloc.state.notes.single.note, 'first draft');
  });
}
