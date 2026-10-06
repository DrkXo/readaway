import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_note.freezed.dart';
part 'reader_note.g.dart';

/// What a [ReaderNote] represents.
///
/// One record type covers all three concepts so a highlight that carries a
/// note body stays a single object, and restyling never has to merge or split
/// records.
enum ReaderNoteType {
  /// A saved position. Never painted.
  bookmark,

  /// A painted range of text, optionally carrying a note body.
  highlight,

  /// A note attached to a range of text. Not painted.
  note,
}

/// How a [ReaderNoteAnchor] addresses its position in the document.
enum NoteAnchorKind {
  /// Characters in the chapter's flow-text space.
  ///
  /// Used by reflowable documents, where the same text re-flows to different
  /// pages at different font sizes but keeps the same character offsets.
  reflowable,

  /// A page index in a fixed-layout document (PDF, CBZ, fixed-layout EPUB).
  page,
}

/// How a painted highlight is drawn.
enum HighlightStyle {
  /// Translucent fill behind the text.
  highlight,

  /// A rule beneath the text.
  underline,

  /// A wavy rule beneath the text.
  squiggly,
}

/// A stable address for a [ReaderNote] inside a document.
///
/// For reflowable documents the address is `[startChar, endChar)` in the
/// chapter's flow-text space, which survives font, margin and theme changes
/// because that space is derived from characters rather than geometry.
/// [text] is the excerpt the range covered when it was created; it is the
/// anchor's self-check, used to re-find the range if offsets ever drift, so a
/// highlight is repaired rather than silently painted in the wrong place.
@freezed
abstract class ReaderNoteAnchor with _$ReaderNoteAnchor {
  const ReaderNoteAnchor._();

  const factory ReaderNoteAnchor({
    @Default(NoteAnchorKind.reflowable)
    @JsonKey(unknownEnumValue: NoteAnchorKind.reflowable)
    NoteAnchorKind kind,
    @Default(0) int chapterIndex,

    /// Character offset of the first covered character, in flow-text space.
    @Default(0) int startChar,

    /// Character offset one past the last covered character.
    @Default(0) int endChar,

    /// Page index for [NoteAnchorKind.page] anchors.
    @Default(0) int pageIndex,

    /// The excerpt this range covered when it was created.
    @Default('') String text,

    /// A short excerpt immediately before the range, used to disambiguate a
    /// repeated [text] when repairing.
    @Default('') String prefix,

    /// A short excerpt immediately after the range, used to disambiguate a
    /// repeated [text] when repairing.
    @Default('') String suffix,

    /// Whether the range could not be re-resolved and the note is therefore
    /// listed but not painted.
    @Default(false) bool orphaned,
  }) = _ReaderNoteAnchor;

  factory ReaderNoteAnchor.fromJson(Map<String, dynamic> json) =>
      _$ReaderNoteAnchorFromJson(json);
}

/// A bookmark, highlight or note in a document.
@freezed
abstract class ReaderNote with _$ReaderNote {
  const ReaderNote._();

  const factory ReaderNote({
    required String id,

    /// What this record represents.
    ///
    /// An unrecognised value reads back as [ReaderNoteType.bookmark], which is
    /// never painted, so a record written by a newer build cannot make the
    /// reader draw something it does not understand.
    @JsonKey(unknownEnumValue: ReaderNoteType.bookmark)
    required ReaderNoteType type,
    required ReaderNoteAnchor anchor,

    /// Painted style. Ignored by [ReaderNoteType.bookmark] and
    /// [ReaderNoteType.note], which are never painted.
    @Default(HighlightStyle.highlight)
    @JsonKey(unknownEnumValue: HighlightStyle.highlight)
    HighlightStyle style,

    /// The persisted colour: either a palette preset key or a `#RRGGBB`
    /// string. Resolved to a `Color` at paint time through the shared
    /// highlight palette, so the value stays theme-agnostic.
    @Default('amber') String colorValue,

    /// The user's note body, in Markdown. Empty for a bare highlight.
    @Default('') String note,

    required DateTime createdAt,
    required DateTime updatedAt,

    /// Soft-delete tombstone. A non-null value hides the note everywhere but
    /// keeps it retrievable for undo and for future sync.
    DateTime? deletedAt,
  }) = _ReaderNote;

  factory ReaderNote.fromJson(Map<String, dynamic> json) =>
      _$ReaderNoteFromJson(json);

  /// Whether this note has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Whether this note draws something over the text.
  bool get isPainted => type == ReaderNoteType.highlight && !isDeleted;

  /// Whether this note carries a note body.
  bool get hasNoteBody => note.trim().isNotEmpty;

  /// Whether this note covers a range rather than a single position.
  bool get isRange => anchor.endChar > anchor.startChar;
}
