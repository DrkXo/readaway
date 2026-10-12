import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';

/// Creates a fake [ReaderNote] with sensible defaults.
ReaderNote fakeReaderNote({
  String id = 'note_1',
  ReaderNoteType type = ReaderNoteType.note,
  ReaderNoteAnchor? anchor,
  HighlightStyle style = HighlightStyle.highlight,
  String colorValue = 'amber',
  String note = 'Sample note text',
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  final at = createdAt ?? DateTime(2026, 1, 1);
  return ReaderNote(
    id: id,
    type: type,
    anchor:
        anchor ??
        const ReaderNoteAnchor(
          chapterIndex: 0,
          startChar: 0,
          endChar: 20,
          pageIndex: 0,
          text: 'Sample passage',
        ),
    style: style,
    colorValue: colorValue,
    note: note,
    createdAt: at,
    updatedAt: updatedAt ?? at,
    deletedAt: deletedAt,
  );
}

/// Creates a fake bookmark note.
ReaderNote fakeBookmark({
  String id = 'b1',
  int pageIndex = 0,
  int chapterIndex = 0,
  int startChar = 0,
  int endChar = 0,
  NoteAnchorKind? kind,
  String? text,
}) => fakeReaderNote(
  id: id,
  type: ReaderNoteType.bookmark,
  anchor: ReaderNoteAnchor(
    kind:
        kind ??
        ((startChar != 0 || endChar != 0)
            ? NoteAnchorKind.reflowable
            : NoteAnchorKind.page),
    chapterIndex: chapterIndex,
    pageIndex: pageIndex,
    startChar: startChar,
    endChar: endChar,
    text: text ?? 'Page ${pageIndex + 1}',
  ),
  note: '',
);

/// Creates a fake highlight note.
ReaderNote fakeHighlight({
  String id = 'h1',
  int pageIndex = 0,
  int chapterIndex = 0,
  int startChar = 0,
  int endChar = 20,
  String text = 'Highlighted text',
  String colorValue = 'amber',
  HighlightStyle style = HighlightStyle.highlight,
  String note = '',
  DateTime? deletedAt,
}) => fakeReaderNote(
  id: id,
  type: ReaderNoteType.highlight,
  anchor: ReaderNoteAnchor(
    chapterIndex: chapterIndex,
    startChar: startChar,
    endChar: endChar,
    pageIndex: pageIndex,
    text: text,
  ),
  style: style,
  colorValue: colorValue,
  note: note,
  deletedAt: deletedAt,
);

/// Creates a fake [DocumentNotes] record with sensible defaults.
DocumentNotes fakeDocumentNotes({
  String documentPath = '/books/test_book.epub',
  int schemaVersion = kDocumentNotesSchemaVersion,
  List<ReaderNote> notes = const [],
  DateTime? updatedAt,
}) => DocumentNotes(
  documentPath: documentPath,
  schemaVersion: schemaVersion,
  notes: notes,
  updatedAt: updatedAt ?? DateTime(2026, 1, 1),
);
