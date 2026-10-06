import '../../../domain/entity/reader_note.dart';

/// The painted style and colour a new highlight gets.
///
/// Placeholders until reader-wide annotation defaults land in settings. Shared
/// rather than declared where they happen to be used, so the selection menu and
/// the note editor cannot disagree about what a default highlight looks like.
const HighlightStyle kDefaultHighlightStyle = HighlightStyle.highlight;

/// The palette's amber preset, which stays legible on both light and dark pages.
const String kDefaultHighlightColorValue = 'amber';
