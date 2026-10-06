import '../entity/document_notes.dart';
import '../entity/reader_note.dart';

/// Monotonic counter that keeps two notes created in the same microsecond
/// apart, matching the convention the toast service uses.
int _readerNoteIdCounter = 0;

/// Creates a unique id for a [ReaderNote].
///
/// Timestamp plus a counter is unique within a session without pulling in a
/// uuid package for a value that never leaves the device.
String newReaderNoteId() =>
    'note_${++_readerNoteIdCounter}_${DateTime.now().microsecondsSinceEpoch}';

/// Pure list operations over a document's notes.
///
/// Deliberately free of storage and of bloc state: the rules that decide what
/// a note list looks like — a delete tombstones rather than removes, a restyle
/// keeps identity — are the part worth testing directly, and they need neither
/// a Hive box nor a running bloc to exercise.
abstract final class ReaderNoteOperations {
  /// Replaces the note with the same id, or appends it when the id is new.
  static List<ReaderNote> upsert(List<ReaderNote> notes, ReaderNote note) {
    final index = notes.indexWhere((existing) => existing.id == note.id);
    if (index < 0) return [...notes, note];
    final next = [...notes];
    next[index] = note;
    return next;
  }

  /// Tombstones the note with [id].
  ///
  /// Returns [notes] unchanged when the id is absent, so a repeated delete
  /// cannot corrupt the list by removing the wrong record, and unchanged when
  /// the note is already tombstoned, so a repeated delete cannot rewrite *when*
  /// the reader deleted it.
  static List<ReaderNote> tombstone(
    List<ReaderNote> notes,
    String id,
    DateTime now,
  ) {
    final index = notes.indexWhere((note) => note.id == id);
    if (index < 0 || notes[index].deletedAt != null) return notes;
    final next = [...notes];
    next[index] = next[index].copyWith(deletedAt: now, updatedAt: now);
    return next;
  }

  /// Clears the tombstone on the note with [id], preserving its original
  /// content so an undo restores exactly what was deleted.
  static List<ReaderNote> restore(
    List<ReaderNote> notes,
    String id,
    DateTime now,
  ) {
    final index = notes.indexWhere((note) => note.id == id);
    if (index < 0 || notes[index].deletedAt == null) return notes;
    final next = [...notes];
    next[index] = next[index].copyWith(deletedAt: null, updatedAt: now);
    return next;
  }

  /// The note with [id], whether or not it is tombstoned.
  static ReaderNote? byId(List<ReaderNote> notes, String id) {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// The live highlight covering exactly the same range as [anchor].
  ///
  /// Exact match rather than overlap: re-highlighting the same words toggles
  /// the highlight off, while a genuine overlap stays as two records, which is
  /// what a reader expects when extending a highlight by a word.
  static ReaderNote? identicalHighlight(
    List<ReaderNote> notes,
    ReaderNoteAnchor anchor,
  ) {
    for (final note in notes) {
      if (note.isDeleted) continue;
      if (note.type != ReaderNoteType.highlight) continue;
      if (note.anchor.chapterIndex != anchor.chapterIndex) continue;
      if (note.anchor.startChar != anchor.startChar) continue;
      if (note.anchor.endChar != anchor.endChar) continue;
      return note;
    }
    return null;
  }

  /// The live bookmark already sitting at [anchor].
  ///
  /// Bookmarks address a single position, not a range, so the comparison is by
  /// page index for fixed-layout documents and by chapter plus start offset for
  /// reflowable ones. Re-bookmarking the same spot therefore toggles off rather
  /// than stacking duplicates.
  static ReaderNote? identicalBookmark(
    List<ReaderNote> notes,
    ReaderNoteAnchor anchor,
  ) {
    for (final note in notes) {
      if (note.isDeleted) continue;
      if (note.type != ReaderNoteType.bookmark) continue;
      if (note.anchor.kind != anchor.kind) continue;
      final same = anchor.kind == NoteAnchorKind.page
          ? note.anchor.pageIndex == anchor.pageIndex
          : note.anchor.chapterIndex == anchor.chapterIndex &&
                note.anchor.startChar == anchor.startChar;
      if (same) return note;
    }
    return null;
  }

  /// Live notes grouped by chapter, for per-chapter lookups while painting.
  static Map<int, List<ReaderNote>> indexByChapter(List<ReaderNote> notes) {
    final index = <int, List<ReaderNote>>{};
    for (final note in notes) {
      if (note.isDeleted) continue;
      (index[note.anchor.chapterIndex] ??= <ReaderNote>[]).add(note);
    }
    // Freeze the inner lists so a state consumer cannot mutate the index.
    return {
      for (final entry in index.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }
}

/// Convenience view over a [DocumentNotes] record.
extension ReaderNoteListX on List<ReaderNote> {
  /// A new record carrying these notes, ready to hand to the repository.
  DocumentNotes asDocument(String documentPath, {DateTime? updatedAt}) =>
      DocumentNotes(
        documentPath: documentPath,
        notes: this,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
