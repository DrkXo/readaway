part of 'annotations_bloc.dart';

/// Where the annotations of the open document are in their lifecycle.
enum AnnotationsStatus {
  /// No document has been loaded yet.
  idle,

  /// The document's notes are being read from storage.
  loading,

  /// The document's notes are loaded and mutations may be applied.
  ready,

  /// The document's notes could not be read. [AnnotationsState.failure] says
  /// why.
  failure,
}

/// The notes of the open document, plus the Annotations tab's filter.
@freezed
abstract class AnnotationsState with _$AnnotationsState {
  const AnnotationsState._();

  const factory AnnotationsState({
    @Default(AnnotationsStatus.idle) AnnotationsStatus status,

    /// Set only for a failed *load*, which the panels render as an error view.
    /// A failed *mutation* is reported through [AnnotationsBloc.failures]
    /// instead, so a transient write error cannot replace the list the reader
    /// is looking at with an error screen.
    Failure? failure,
    String? documentPath,
    @Default(<ReaderNote>[]) List<ReaderNote> notes,

    /// Live notes grouped by chapter. Kept in state so the paint layer's
    /// per-chapter lookup is a map access rather than a scan on every frame.
    @Default(<int, List<ReaderNote>>{}) Map<int, List<ReaderNote>> byChapter,
    @Default(ReaderNotesFilter()) ReaderNotesFilter filter,
  }) = _AnnotationsState;

  /// Whether a document's notes are loaded and usable.
  bool get hasDocument =>
      documentPath != null && status == AnnotationsStatus.ready;

  /// Live highlights and notes, newest last. Bookmarks are not included; they
  /// belong to their own tab.
  List<ReaderNote> get annotations => notes
      .where((note) => !note.isDeleted && note.type != ReaderNoteType.bookmark)
      .toList(growable: false);

  /// Live bookmarks, in the order they were created.
  List<ReaderNote> get bookmarks => notes
      .where((note) => !note.isDeleted && note.type == ReaderNoteType.bookmark)
      .toList(growable: false);

  /// The annotations the list should show, after [filter].
  List<ReaderNote> get visibleAnnotations =>
      annotations.where(filter.matches).toList(growable: false);

  /// Live notes anchored to [chapterIndex]. Empty when the chapter has none,
  /// which is the common case and must not allocate per call.
  List<ReaderNote> notesForChapter(int chapterIndex) =>
      byChapter[chapterIndex] ?? const <ReaderNote>[];

  /// The live bookmark saved at [pageIndex], if any.
  ReaderNote? bookmarkForPage(int pageIndex) {
    for (final bookmark in bookmarks) {
      if (bookmark.anchor.pageIndex == pageIndex) return bookmark;
    }
    return null;
  }

  /// Whether a bookmark is saved at [anchor], for the toolbar button's state.
  bool hasBookmarkAt(ReaderNoteAnchor anchor) =>
      ReaderNoteOperations.identicalBookmark(notes, anchor) != null;

  /// The colours in use by live highlights, in first-seen order, for the
  /// filter menu.
  List<String> get availableColors {
    final seen = <String>{};
    final colors = <String>[];
    for (final note in annotations) {
      if (note.type != ReaderNoteType.highlight) continue;
      if (seen.add(note.colorValue)) colors.add(note.colorValue);
    }
    return colors;
  }

  /// The styles in use by live highlights, for the filter menu.
  List<HighlightStyle> get availableStyles {
    final styles = <HighlightStyle>{};
    for (final note in annotations) {
      if (note.type == ReaderNoteType.highlight) styles.add(note.style);
    }
    return HighlightStyle.values.where(styles.contains).toList(growable: false);
  }
}
