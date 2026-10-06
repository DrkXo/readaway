import 'package:freezed_annotation/freezed_annotation.dart';

import 'reader_note.dart';

part 'reader_notes_filter.freezed.dart';

/// Which live annotations the list shows.
enum ReaderNoteKindFilter {
  /// Every highlight and note. Bookmarks live in their own tab.
  all,

  /// Only painted highlights.
  highlights,

  /// Only records that carry a note body, whether or not they are painted.
  notes,
}

/// The Annotations tab's active filter.
///
/// Colour and style are expressed as *exclusions*: a note is hidden when its
/// colour or style is excluded, so a colour the user has never seen — one just
/// introduced, or added by a future preset — is visible by default rather than
/// silently filtered out.
@freezed
abstract class ReaderNotesFilter with _$ReaderNotesFilter {
  const ReaderNotesFilter._();

  const factory ReaderNotesFilter({
    @Default(ReaderNoteKindFilter.all) ReaderNoteKindFilter kind,
    @Default('') String query,
    @Default(<String>{}) Set<String> excludedColors,
    @Default(<HighlightStyle>{}) Set<HighlightStyle> excludedStyles,
  }) = _ReaderNotesFilter;

  /// Whether anything is narrowing the list, so the UI can show a reset
  /// affordance only when it would actually do something.
  bool get isActive =>
      kind != ReaderNoteKindFilter.all ||
      query.trim().isNotEmpty ||
      excludedColors.isNotEmpty ||
      excludedStyles.isNotEmpty;

  /// Whether the live annotation [note] passes this filter.
  ///
  /// Callers must not pass a bookmark: this filter describes the Annotations
  /// tab, which does not list them.
  bool matches(ReaderNote note) {
    final kindMatches = switch (kind) {
      ReaderNoteKindFilter.all => true,
      ReaderNoteKindFilter.highlights => note.type == ReaderNoteType.highlight,
      ReaderNoteKindFilter.notes => note.hasNoteBody,
    };
    if (!kindMatches) return false;

    // Colour and style describe a painted highlight. A record that draws
    // nothing — a note without a highlight — has no colour to exclude, so
    // excluding one must not hide it.
    if (note.type == ReaderNoteType.highlight) {
      if (excludedColors.contains(note.colorValue)) return false;
      if (excludedStyles.contains(note.style)) return false;
    }

    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    // The excerpt is searched as well as the note body: the excerpt is what
    // the reader remembers seeing, and often the only text they can quote.
    return note.note.toLowerCase().contains(needle) ||
        note.anchor.text.toLowerCase().contains(needle);
  }
}
