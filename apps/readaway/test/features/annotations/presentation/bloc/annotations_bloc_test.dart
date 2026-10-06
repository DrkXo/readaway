import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_notes_filter.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';

import '../../../../helpers/test_mocks.dart';

const _path = '/books/a.epub';

const _anchor = ReaderNoteAnchor(
  chapterIndex: 2,
  startChar: 10,
  endChar: 20,
  pageIndex: 3,
  text: 'a passage',
);

ReaderNote _highlight({
  String id = 'h1',
  int chapterIndex = 2,
  int startChar = 10,
  int endChar = 20,
  HighlightStyle style = HighlightStyle.highlight,
  String colorValue = 'amber',
  String note = '',
  DateTime? deletedAt,
}) {
  final at = DateTime(2026, 1, 1);
  return ReaderNote(
    id: id,
    type: ReaderNoteType.highlight,
    anchor: ReaderNoteAnchor(
      chapterIndex: chapterIndex,
      startChar: startChar,
      endChar: endChar,
      pageIndex: 3,
      text: 'a passage',
    ),
    style: style,
    colorValue: colorValue,
    note: note,
    createdAt: at,
    updatedAt: at,
    deletedAt: deletedAt,
  );
}

ReaderNote _bookmark({String id = 'b1', int pageIndex = 3}) {
  final at = DateTime(2026, 1, 1);
  return ReaderNote(
    id: id,
    type: ReaderNoteType.bookmark,
    anchor: ReaderNoteAnchor(
      kind: NoteAnchorKind.page,
      chapterIndex: pageIndex,
      pageIndex: pageIndex,
      text: 'Page ${pageIndex + 1}',
    ),
    createdAt: at,
    updatedAt: at,
  );
}

ReaderNote _textNote({String id = 'n1', String note = 'why it matters'}) {
  final at = DateTime(2026, 1, 1);
  return ReaderNote(
    id: id,
    type: ReaderNoteType.note,
    anchor: _anchor,
    note: note,
    createdAt: at,
    updatedAt: at,
  );
}

DocumentNotes _record(List<ReaderNote> notes, {String path = _path}) =>
    DocumentNotes(
      documentPath: path,
      schemaVersion: kDocumentNotesSchemaVersion,
      notes: notes,
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late MockAnnotationsRepository repository;

  /// Stubs [AnnotationsRepository.getForDocument] to return [notes].
  void stubLoad(String path, List<ReaderNote> notes) {
    when(repository.getForDocument(path)).thenAnswer((_) async {
      final Result<DocumentNotes> result = Success(
        _record(notes, path: path),
      );
      return result;
    });
  }

  /// Stubs the load to fail, as an unreadable box would.
  void stubLoadFailure(String path) {
    when(repository.getForDocument(path)).thenAnswer((_) async {
      const Result<DocumentNotes> result = Failed(
        StorageReadFailure('annotations'),
      );
      return result;
    });
  }

  /// Echoes back whatever the bloc writes, so state mirrors storage.
  void stubSaveEcho() {
    when(repository.save(any)).thenAnswer((invocation) async {
      final Result<DocumentNotes> result = Success(
        invocation.positionalArguments.first as DocumentNotes,
      );
      return result;
    });
  }

  void stubSaveFailure() {
    when(repository.save(any)).thenAnswer((_) async {
      const Result<DocumentNotes> result = Failed(
        StorageWriteFailure('annotations'),
      );
      return result;
    });
  }

  setUp(() {
    repository = MockAnnotationsRepository();
    stubSaveEcho();
  });

  AnnotationsBloc build() => AnnotationsBloc(repository);

  /// Subscribes before adding, so the awaited state cannot be missed.
  Future<AnnotationsState> waitFor(
    AnnotationsBloc bloc,
    bool Function(AnnotationsState state) predicate,
  ) => bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 5));

  /// A bloc with [_path] already loaded and [notes] in state.
  Future<AnnotationsBloc> loadedBloc([
    List<ReaderNote> notes = const [],
  ]) async {
    stubLoad(_path, notes);
    final bloc = build();
    addTearDown(bloc.close);
    final ready = waitFor(bloc, (s) => s.status == AnnotationsStatus.ready);
    bloc.add(const AnnotationsEvent.loadForDocument(documentPath: _path));
    await ready;
    return bloc;
  }

  group('loadForDocument', () {
    blocTest<AnnotationsBloc, AnnotationsState>(
      'reports loading then ready, with the notes indexed by chapter',
      setUp: () => stubLoad(_path, [_highlight(), _bookmark()]),
      build: build,
      act: (bloc) => bloc.add(
        const AnnotationsEvent.loadForDocument(documentPath: _path),
      ),
      expect: () => [
        isA<AnnotationsState>().having(
          (s) => s.status,
          'status',
          AnnotationsStatus.loading,
        ),
        isA<AnnotationsState>()
            .having((s) => s.status, 'status', AnnotationsStatus.ready)
            .having((s) => s.documentPath, 'documentPath', _path)
            .having((s) => s.annotations.length, 'annotations', 1)
            .having((s) => s.bookmarks.length, 'bookmarks', 1)
            .having((s) => s.notesForChapter(2).length, 'chapter 2 notes', 1),
      ],
    );

    blocTest<AnnotationsBloc, AnnotationsState>(
      'surfaces a load failure for the panels to render',
      setUp: () => stubLoadFailure(_path),
      build: build,
      act: (bloc) => bloc.add(
        const AnnotationsEvent.loadForDocument(documentPath: _path),
      ),
      expect: () => [
        isA<AnnotationsState>().having(
          (s) => s.status,
          'status',
          AnnotationsStatus.loading,
        ),
        isA<AnnotationsState>()
            .having((s) => s.status, 'status', AnnotationsStatus.failure)
            .having((s) => s.failure, 'failure', isA<StorageReadFailure>())
            .having((s) => s.hasDocument, 'hasDocument', isFalse),
      ],
    );

    test('does not re-read a document that is already loaded', () async {
      final bloc = await loadedBloc([_highlight()]);

      bloc.add(const AnnotationsEvent.loadForDocument(documentPath: _path));
      await Future<void>.delayed(Duration.zero);

      verify(repository.getForDocument(_path)).called(1);
    });

    test('clear returns to the idle state', () async {
      final bloc = await loadedBloc([_highlight()]);

      bloc.add(const AnnotationsEvent.clear());
      final idle = await waitFor(
        bloc,
        (s) => s.status == AnnotationsStatus.idle,
      );

      expect(idle.notes, isEmpty);
      expect(idle.documentPath, isNull);
    });
  });

  group('addHighlight', () {
    test('creates a painted highlight and persists it', () async {
      final bloc = await loadedBloc();

      final done = waitFor(bloc, (s) => s.annotations.isNotEmpty);
      bloc.add(
        const AnnotationsEvent.addHighlight(
          anchor: _anchor,
          style: HighlightStyle.underline,
          colorValue: 'sky',
        ),
      );
      final note = (await done).annotations.single;

      expect(note.type, ReaderNoteType.highlight);
      expect(note.style, HighlightStyle.underline);
      expect(note.colorValue, 'sky');
      expect(note.isPainted, isTrue);
      expect(note.anchor, _anchor);
      expect(note.note, isEmpty);

      final saved = verify(repository.save(captureAny)).captured.single;
      expect((saved as DocumentNotes).notes.single.id, note.id);
    });

    test(
      'toggles off when the exact same range is highlighted again',
      () async {
        final bloc = await loadedBloc([_highlight()]);

        final done = waitFor(bloc, (s) => s.annotations.isEmpty);
        bloc.add(
          const AnnotationsEvent.addHighlight(
            anchor: _anchor,
            style: HighlightStyle.highlight,
            colorValue: 'amber',
          ),
        );

        expect((await done).annotations, isEmpty);
        // Tombstoned rather than dropped, so undo can bring it back.
        expect(bloc.state.notes.single.isDeleted, isTrue);
      },
    );

    test('creates a second note for a different range', () async {
      final bloc = await loadedBloc([_highlight()]);

      final done = waitFor(bloc, (s) => s.annotations.length == 2);
      bloc.add(
        const AnnotationsEvent.addHighlight(
          anchor: ReaderNoteAnchor(
            chapterIndex: 2,
            startChar: 30,
            endChar: 45,
            text: 'another passage',
          ),
          style: HighlightStyle.highlight,
          colorValue: 'amber',
        ),
      );

      expect((await done).annotations, hasLength(2));
    });
  });

  group('addNote', () {
    test('creates an unpainted note carrying the body', () async {
      final bloc = await loadedBloc();

      final done = waitFor(bloc, (s) => s.annotations.isNotEmpty);
      bloc.add(
        const AnnotationsEvent.addNote(anchor: _anchor, note: 'worth quoting'),
      );
      final note = (await done).annotations.single;

      expect(note.type, ReaderNoteType.note);
      expect(note.note, 'worth quoting');
      expect(note.hasNoteBody, isTrue);
      expect(note.isPainted, isFalse);
    });
  });

  group('toggleBookmark', () {
    test('adds then removes a bookmark at the same position', () async {
      final bloc = await loadedBloc();

      final added = waitFor(bloc, (s) => s.bookmarks.isNotEmpty);
      bloc.add(const AnnotationsEvent.toggleBookmark(anchor: _anchor));
      expect((await added).bookmarks.single.type, ReaderNoteType.bookmark);

      final removed = waitFor(bloc, (s) => s.bookmarks.isEmpty);
      bloc.add(const AnnotationsEvent.toggleBookmark(anchor: _anchor));
      expect((await removed).bookmarks, isEmpty);
    });

    test('hasBookmarkAt reflects the current page', () async {
      final bloc = await loadedBloc();

      expect(bloc.state.hasBookmarkAt(_anchor), isFalse);
      final added = waitFor(bloc, (s) => s.hasBookmarkAt(_anchor));
      bloc.add(const AnnotationsEvent.toggleBookmark(anchor: _anchor));
      await added;

      expect(bloc.state.hasBookmarkAt(_anchor), isTrue);
      // A different position is still unbookmarked.
      expect(
        bloc.state.hasBookmarkAt(
          const ReaderNoteAnchor(chapterIndex: 2, startChar: 99),
        ),
        isFalse,
      );
    });
  });

  group('editing', () {
    test('updateNoteBody replaces the body and keeps identity', () async {
      final bloc = await loadedBloc([_highlight()]);

      final done = waitFor(bloc, (s) => s.annotations.single.hasNoteBody);
      bloc.add(
        const AnnotationsEvent.updateNoteBody(id: 'h1', note: 'new body'),
      );
      final note = (await done).annotations.single;

      expect(note.note, 'new body');
      expect(note.id, 'h1');
      expect(note.createdAt, DateTime(2026, 1, 1));
      expect(note.anchor, _anchor);
    });

    test('restyleNote repaints and promotes a note into a highlight', () async {
      final bloc = await loadedBloc([_textNote()]);

      final done = waitFor(bloc, (s) => s.annotations.single.isPainted);
      bloc.add(
        const AnnotationsEvent.restyleNote(
          id: 'n1',
          style: HighlightStyle.squiggly,
          colorValue: '#00FF00',
        ),
      );
      final note = (await done).annotations.single;

      expect(note.type, ReaderNoteType.highlight);
      expect(note.style, HighlightStyle.squiggly);
      expect(note.colorValue, '#00FF00');
      // The body is not collateral damage of a restyle.
      expect(note.note, 'why it matters');
    });
  });

  group('deleting', () {
    test(
      'deleteNote tombstones and restoreNote brings it back intact',
      () async {
        final bloc = await loadedBloc([_highlight(note: 'keep me')]);

        final deleted = waitFor(bloc, (s) => s.annotations.isEmpty);
        bloc.add(const AnnotationsEvent.deleteNote(id: 'h1'));
        await deleted;
        expect(bloc.state.notes.single.isDeleted, isTrue);

        final restored = waitFor(bloc, (s) => s.annotations.isNotEmpty);
        bloc.add(const AnnotationsEvent.restoreNote(id: 'h1'));
        final note = (await restored).annotations.single;

        expect(note.note, 'keep me');
        expect(note.style, HighlightStyle.highlight);
      },
    );

    test('deleteAll tombstones every live note', () async {
      final bloc = await loadedBloc([
        _highlight(id: 'h1'),
        _textNote(id: 'n1'),
        _bookmark(id: 'b1'),
      ]);

      final done = waitFor(
        bloc,
        (s) => s.annotations.isEmpty && s.bookmarks.isEmpty,
      );
      bloc.add(const AnnotationsEvent.deleteAll());
      await done;

      expect(bloc.state.notes, hasLength(3));
      expect(bloc.state.notes.every((n) => n.isDeleted), isTrue);
    });

    test('a write failure is reported without discarding the list', () async {
      final bloc = await loadedBloc([_highlight()]);
      stubSaveFailure();

      final reported = bloc.failures.first.timeout(const Duration(seconds: 5));
      bloc.add(const AnnotationsEvent.deleteNote(id: 'h1'));

      expect(await reported, isA<StorageWriteFailure>());
      // The reader's list is untouched and still usable.
      expect(bloc.state.status, AnnotationsStatus.ready);
      expect(bloc.state.annotations, hasLength(1));
    });
  });

  group('filter', () {
    test('visibleAnnotations honours kind, search and exclusions', () async {
      final bloc = await loadedBloc([
        _highlight(id: 'amber', colorValue: 'amber', note: 'first passage'),
        _highlight(
          id: 'sky',
          colorValue: 'sky',
          style: HighlightStyle.underline,
          startChar: 40,
          endChar: 60,
        ),
        _textNote(id: 'noteonly', note: 'a private thought'),
        _bookmark(),
      ]);

      // Bookmarks are never in the Annotations tab.
      expect(bloc.state.visibleAnnotations.map((n) => n.id), [
        'amber',
        'sky',
        'noteonly',
      ]);

      bloc.add(
        const AnnotationsEvent.filterChanged(
          filter: ReaderNotesFilter(kind: ReaderNoteKindFilter.notes),
        ),
      );
      await waitFor(bloc, (s) => s.filter.kind == ReaderNoteKindFilter.notes);
      // "Notes" means records carrying a body, painted or not.
      expect(bloc.state.visibleAnnotations.map((n) => n.id), [
        'amber',
        'noteonly',
      ]);

      bloc.add(
        const AnnotationsEvent.filterChanged(
          filter: ReaderNotesFilter(query: 'PRIVATE'),
        ),
      );
      await waitFor(bloc, (s) => s.filter.query == 'PRIVATE');
      // The excerpt is searched too, and the query is case-insensitive.
      expect(bloc.state.visibleAnnotations.map((n) => n.id), ['noteonly']);

      bloc.add(
        const AnnotationsEvent.filterChanged(
          filter: ReaderNotesFilter(excludedColors: {'amber'}),
        ),
      );
      await waitFor(bloc, (s) => s.filter.excludedColors.isNotEmpty);
      expect(bloc.state.visibleAnnotations.map((n) => n.id), [
        'sky',
        'noteonly',
      ]);
    });

    test(
      'availableColors and availableStyles list what is on screen',
      () async {
        final bloc = await loadedBloc([
          _highlight(id: 'h1', colorValue: 'amber'),
          _highlight(
            id: 'h2',
            colorValue: 'sky',
            style: HighlightStyle.squiggly,
          ),
          _highlight(id: 'h3', colorValue: 'amber'),
          _textNote(),
        ]);

        expect(bloc.state.availableColors, ['amber', 'sky']);
        expect(bloc.state.availableStyles, [
          HighlightStyle.highlight,
          HighlightStyle.squiggly,
        ]);
      },
    );

    test('loading a new document resets the filter', () async {
      final bloc = await loadedBloc([_highlight()]);
      bloc.add(
        const AnnotationsEvent.filterChanged(
          filter: ReaderNotesFilter(query: 'stale'),
        ),
      );
      await waitFor(bloc, (s) => s.filter.query == 'stale');

      stubLoad('/books/b.epub', const []);
      final loaded = waitFor(bloc, (s) => s.documentPath == '/books/b.epub');
      bloc.add(
        const AnnotationsEvent.loadForDocument(documentPath: '/books/b.epub'),
      );

      expect((await loaded).filter.isActive, isFalse);
    });
  });

  group('bookmarkForPage', () {
    test('finds the bookmark saved at a page', () async {
      final bloc = await loadedBloc([_bookmark(id: 'b1', pageIndex: 3)]);

      expect(bloc.state.bookmarkForPage(3)?.id, 'b1');
      expect(bloc.state.bookmarkForPage(4), isNull);
    });
  });
}
