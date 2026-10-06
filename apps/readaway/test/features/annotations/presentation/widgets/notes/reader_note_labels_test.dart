import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/widgets/notes/reader_note_labels.dart';

final _at = DateTime(2026, 1, 1);

ReaderNote _note({
  ReaderNoteType type = ReaderNoteType.highlight,
  HighlightStyle style = HighlightStyle.highlight,
}) => ReaderNote(
  id: 'n1',
  type: type,
  anchor: const ReaderNoteAnchor(chapterIndex: 2, startChar: 0, endChar: 5),
  style: style,
  createdAt: _at,
  updatedAt: _at,
);

void main() {
  group('readerHighlightStyleLabel', () {
    test('names every painted style', () {
      expect(readerHighlightStyleLabel(HighlightStyle.highlight), 'Highlight');
      expect(readerHighlightStyleLabel(HighlightStyle.underline), 'Underline');
      expect(readerHighlightStyleLabel(HighlightStyle.squiggly), 'Squiggly');
    });
  });

  group('readerNoteKindLabel', () {
    test('describes a highlight by the style actually drawn', () {
      expect(
        readerNoteKindLabel(
          _note(type: ReaderNoteType.highlight, style: HighlightStyle.squiggly),
        ),
        'Squiggly',
      );
    });

    test('names an unpainted note and a bookmark plainly', () {
      expect(readerNoteKindLabel(_note(type: ReaderNoteType.note)), 'Note');
      expect(
        readerNoteKindLabel(_note(type: ReaderNoteType.bookmark)),
        'Bookmark',
      );
    });
  });

  group('readerNoteLocationLabel', () {
    test('counts pages from one', () {
      expect(
        readerNoteLocationLabel(
          const ReaderNoteAnchor(kind: NoteAnchorKind.page, pageIndex: 0),
        ),
        'Page 1',
      );
    });

    test('counts chapters from one', () {
      expect(
        readerNoteLocationLabel(const ReaderNoteAnchor(chapterIndex: 2)),
        'Chapter 3',
      );
    });
  });

  group('readerNoteColorLabel', () {
    test('prefers the palette name for a preset', () {
      expect(readerNoteColorLabel('amber'), 'Amber');
      expect(readerNoteColorLabel('primary'), 'Primary');
    });

    test('falls back to the value for a custom colour', () {
      expect(readerNoteColorLabel('#FF8800'), '#FF8800');
    });
  });
}
