/// Human-readable names for the annotation vocabulary.
///
/// Shared rather than repeated, because a filter and the rows it hides have to
/// agree: a reader who hides "Underline" must see that word on the rows that
/// disappear, or the filter looks like it did something arbitrary.
library;

import '../../../../../core/theme/tts_highlight_palette.dart';
import '../../../domain/entity/reader_note.dart';

/// What a note is, in words.
///
/// A highlight answers with its painted style, so the name always matches what
/// is actually drawn on the page.
String readerNoteKindLabel(ReaderNote note) => switch (note.type) {
  ReaderNoteType.bookmark => 'Bookmark',
  ReaderNoteType.note => 'Note',
  ReaderNoteType.highlight => readerHighlightStyleLabel(note.style),
};

/// The painted style of a highlight, in words.
String readerHighlightStyleLabel(HighlightStyle style) => switch (style) {
  HighlightStyle.highlight => 'Highlight',
  HighlightStyle.underline => 'Underline',
  HighlightStyle.squiggly => 'Squiggly',
};

/// Where a note sits, in the terms the reader saw when they made it.
String readerNoteLocationLabel(ReaderNoteAnchor anchor) =>
    anchor.kind == NoteAnchorKind.page
    ? 'Page ${anchor.pageIndex + 1}'
    : 'Chapter ${anchor.chapterIndex + 1}';

/// The palette's name for a stored colour value.
///
/// A value that is not a preset is a custom hex the reader typed, and the hex
/// itself is the most useful thing to call it.
String readerNoteColorLabel(String colorValue) {
  for (final option in kTtsHighlightColorOptions) {
    if (option.key == colorValue) return option.label;
  }
  return colorValue;
}
