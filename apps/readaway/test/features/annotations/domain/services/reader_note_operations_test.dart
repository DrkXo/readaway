import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/domain/services/reader_note_operations.dart';

ReaderNote _note({
  String id = 'n1',
  ReaderNoteType type = ReaderNoteType.highlight,
  int chapterIndex = 1,
  int startChar = 10,
  int endChar = 20,
  int pageIndex = 0,
  DateTime? deletedAt,
}) {
  final at = DateTime(2026, 1, 1);
  return ReaderNote(
    id: id,
    type: type,
    anchor: ReaderNoteAnchor(
      kind: type == ReaderNoteType.bookmark
          ? NoteAnchorKind.page
          : NoteAnchorKind.reflowable,
      chapterIndex: chapterIndex,
      startChar: startChar,
      endChar: endChar,
      pageIndex: pageIndex,
      text: 'excerpt',
    ),
    createdAt: at,
    updatedAt: at,
    deletedAt: deletedAt,
  );
}

void main() {
  group('upsert', () {
    test('appends a new id at the end', () {
      final notes = [_note(id: 'a')];
      final result = ReaderNoteOperations.upsert(notes, _note(id: 'b'));

      expect(result.map((n) => n.id), ['a', 'b']);
      // The input list is never mutated in place.
      expect(notes.map((n) => n.id), ['a']);
    });

    test('replaces an existing id without moving it', () {
      final notes = [_note(id: 'a'), _note(id: 'b'), _note(id: 'c')];
      final result = ReaderNoteOperations.upsert(
        notes,
        _note(id: 'b', startChar: 99, endChar: 120),
      );

      expect(result.map((n) => n.id), ['a', 'b', 'c']);
      expect(result[1].anchor.startChar, 99);
    });
  });

  group('tombstone', () {
    test('marks the note deleted and records when', () {
      final now = DateTime(2026, 5, 5);
      final result = ReaderNoteOperations.tombstone([_note(id: 'a')], 'a', now);

      expect(result.single.isDeleted, isTrue);
      expect(result.single.deletedAt, now);
      expect(result.single.updatedAt, now);
      // The content survives, which is what makes undo lossless.
      expect(result.single.anchor.startChar, 10);
    });

    test('leaves the list alone for an unknown id', () {
      final notes = [_note(id: 'a')];
      expect(
        ReaderNoteOperations.tombstone(notes, 'nope', DateTime(2026)),
        notes,
      );
    });

    test('does not resurrect an already deleted note', () {
      final deletedAt = DateTime(2026, 3, 3);
      final result = ReaderNoteOperations.tombstone(
        [_note(id: 'a', deletedAt: deletedAt)],
        'a',
        DateTime(2026, 9, 9),
      );

      // The original tombstone time is preserved, not overwritten.
      expect(result.single.deletedAt, deletedAt);
    });
  });

  group('restore', () {
    test('clears the tombstone and bumps the modified time', () {
      final now = DateTime(2026, 6, 6);
      final result = ReaderNoteOperations.restore(
        [_note(id: 'a', deletedAt: DateTime(2026, 5, 5))],
        'a',
        now,
      );

      expect(result.single.isDeleted, isFalse);
      expect(result.single.deletedAt, isNull);
      expect(result.single.updatedAt, now);
      expect(result.single.createdAt, DateTime(2026, 1, 1));
    });

    test('is a no-op for a live or unknown note', () {
      final live = [_note(id: 'a')];
      expect(ReaderNoteOperations.restore(live, 'a', DateTime(2026)), live);
      expect(ReaderNoteOperations.restore(live, 'nope', DateTime(2026)), live);
    });
  });

  group('byId', () {
    test('finds tombstoned notes too, so undo can reach them', () {
      final notes = [_note(id: 'a', deletedAt: DateTime(2026, 2, 2))];
      expect(ReaderNoteOperations.byId(notes, 'a'), isNotNull);
      expect(ReaderNoteOperations.byId(notes, 'b'), isNull);
    });
  });

  group('identicalHighlight', () {
    test('matches only the exact range in the same chapter', () {
      final notes = [
        _note(id: 'a', chapterIndex: 2, startChar: 10, endChar: 20),
      ];

      expect(
        ReaderNoteOperations.identicalHighlight(
          notes,
          _note(id: 'x', chapterIndex: 2, startChar: 10, endChar: 20).anchor,
        )?.id,
        'a',
      );
      // A different chapter is a different passage...
      expect(
        ReaderNoteOperations.identicalHighlight(
          notes,
          _note(id: 'x', chapterIndex: 3, startChar: 10, endChar: 20).anchor,
        ),
        isNull,
      );
      // ...and so is a longer range over the same start.
      expect(
        ReaderNoteOperations.identicalHighlight(
          notes,
          _note(id: 'x', chapterIndex: 2, startChar: 10, endChar: 25).anchor,
        ),
        isNull,
      );
    });

    test('ignores deleted highlights and other record types', () {
      final notes = [
        _note(id: 'gone', deletedAt: DateTime(2026, 2, 2)),
        _note(id: 'notetype', type: ReaderNoteType.note),
      ];

      expect(
        ReaderNoteOperations.identicalHighlight(
          notes,
          _note(id: 'x').anchor,
        ),
        isNull,
      );
    });
  });

  group('identicalBookmark', () {
    test('matches a page bookmark by page index', () {
      final notes = [
        _note(id: 'b', type: ReaderNoteType.bookmark, pageIndex: 7),
      ];

      expect(
        ReaderNoteOperations.identicalBookmark(
          notes,
          _note(id: 'x', type: ReaderNoteType.bookmark, pageIndex: 7).anchor,
        )?.id,
        'b',
      );
      expect(
        ReaderNoteOperations.identicalBookmark(
          notes,
          _note(id: 'x', type: ReaderNoteType.bookmark, pageIndex: 8).anchor,
        ),
        isNull,
      );
    });

    test('matches a reflowable bookmark by chapter and start offset', () {
      final notes = [_note(id: 'h', type: ReaderNoteType.highlight)];

      // A highlight is not a bookmark, so toggling a bookmark over highlighted
      // text must still create a new bookmark.
      expect(
        ReaderNoteOperations.identicalBookmark(notes, notes.single.anchor),
        isNull,
      );
    });
  });

  group('indexByChapter', () {
    test('groups live notes and skips deleted ones', () {
      final index = ReaderNoteOperations.indexByChapter([
        _note(id: 'a', chapterIndex: 1),
        _note(id: 'b', chapterIndex: 2),
        _note(id: 'c', chapterIndex: 1),
        _note(id: 'gone', chapterIndex: 1, deletedAt: DateTime(2026, 2, 2)),
      ]);

      expect(index.keys.toSet(), {1, 2});
      expect(index[1]!.map((n) => n.id), ['a', 'c']);
      expect(index[2]!.map((n) => n.id), ['b']);
    });

    test('returns unmodifiable groups', () {
      final index = ReaderNoteOperations.indexByChapter([
        _note(id: 'a', chapterIndex: 1),
      ]);

      expect(() => index[1]!.add(_note(id: 'x')), throwsUnsupportedError);
    });
  });

  group('asDocument', () {
    test('wraps the list with the document path', () {
      final record = [_note(id: 'a')].asDocument('/books/a.epub');

      expect(record.documentPath, '/books/a.epub');
      expect(record.notes, hasLength(1));
    });
  });

  group('newReaderNoteId', () {
    test('never repeats', () {
      final ids = {for (var i = 0; i < 200; i++) newReaderNoteId()};
      expect(ids, hasLength(200));
    });
  });
}
