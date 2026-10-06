import 'package:freezed_annotation/freezed_annotation.dart';

import 'reader_note.dart';

part 'document_notes.freezed.dart';
part 'document_notes.g.dart';

/// Schema version of a persisted [DocumentNotes] record.
///
/// Bumped when a stored shape changes in a way that needs migrating. Records
/// written before this field existed read back as version 0.
const int kDocumentNotesSchemaVersion = 1;

/// Every note belonging to one document, stored as a single record keyed by
/// the document path.
///
/// One record per document keeps a change atomic: a note is added, restyled or
/// deleted by rewriting the document's list, so a document can never end up
/// half-updated. The list stays small enough that this is not a cost worth
/// trading for a per-note key.
@freezed
abstract class DocumentNotes with _$DocumentNotes {
  const DocumentNotes._();

  const factory DocumentNotes({
    required String documentPath,
    @Default(0) int schemaVersion,
    @Default(<ReaderNote>[]) List<ReaderNote> notes,
    required DateTime updatedAt,
  }) = _DocumentNotes;

  factory DocumentNotes.fromJson(Map<String, dynamic> json) =>
      _$DocumentNotesFromJson(json);

  /// Records without a tombstone, in stored order.
  List<ReaderNote> get live =>
      notes.where((note) => !note.isDeleted).toList(growable: false);

  /// Live notes of [type], in stored order.
  List<ReaderNote> liveOfType(ReaderNoteType type) => notes
      .where((note) => !note.isDeleted && note.type == type)
      .toList(
        growable: false,
      );

  /// Live notes anchored to [chapterIndex], in stored order.
  List<ReaderNote> liveInChapter(int chapterIndex) => notes
      .where(
        (note) => !note.isDeleted && note.anchor.chapterIndex == chapterIndex,
      )
      .toList(growable: false);
}
