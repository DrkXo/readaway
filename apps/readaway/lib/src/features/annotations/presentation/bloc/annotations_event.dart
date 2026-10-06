part of 'annotations_bloc.dart';

/// Everything that can change a document's bookmarks, highlights and notes.
@freezed
sealed class AnnotationsEvent with _$AnnotationsEvent {
  /// Loads the notes stored for [documentPath].
  const factory AnnotationsEvent.loadForDocument({
    required String documentPath,
  }) = _LoadForDocument;

  /// Drops the in-memory notes, for when the reader closes its document.
  const factory AnnotationsEvent.clear() = _Clear;

  /// Paints [anchor] with [style] and [colorValue].
  ///
  /// When a live highlight already covers exactly that range this removes it
  /// instead, so the reader's "Highlight" action behaves as a toggle.
  const factory AnnotationsEvent.addHighlight({
    required ReaderNoteAnchor anchor,
    required HighlightStyle style,
    required String colorValue,
  }) = _AddHighlight;

  /// Attaches a note to [anchor] without painting it.
  const factory AnnotationsEvent.addNote({
    required ReaderNoteAnchor anchor,
    required String note,
  }) = _AddNote;

  /// Saves [anchor] as a bookmark, or removes the bookmark already there.
  const factory AnnotationsEvent.toggleBookmark({
    required ReaderNoteAnchor anchor,
  }) = _ToggleBookmark;

  /// Replaces the note body of the note with [id].
  const factory AnnotationsEvent.updateNoteBody({
    required String id,
    required String note,
  }) = _UpdateNoteBody;

  /// Repaints the note with [id]. Identity and timestamps are preserved.
  const factory AnnotationsEvent.restyleNote({
    required String id,
    required HighlightStyle style,
    required String colorValue,
  }) = _RestyleNote;

  /// Tombstones the note with [id].
  const factory AnnotationsEvent.deleteNote({required String id}) = _DeleteNote;

  /// Clears the tombstone on [id], restoring the note exactly as it was.
  const factory AnnotationsEvent.restoreNote({required String id}) =
      _RestoreNote;

  /// Tombstones every note in the open document.
  const factory AnnotationsEvent.deleteAll() = _DeleteAll;

  /// Applies [filter] to the Annotations tab.
  const factory AnnotationsEvent.filterChanged({
    required ReaderNotesFilter filter,
  }) = _FilterChanged;
}
