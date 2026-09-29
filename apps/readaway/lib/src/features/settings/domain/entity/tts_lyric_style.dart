import 'package:freezed_annotation/freezed_annotation.dart';

part 'tts_lyric_style.freezed.dart';
part 'tts_lyric_style.g.dart';

/// Horizontal alignment of a sentence's glyphs inside the box it is painted
/// into.
///
/// Nearly invisible on this view, and that is worth knowing before reaching for
/// it: the package sizes each line's painter to the text itself, so on a
/// sentence that fits on one line there is no slack for an alignment to
/// distribute and every one of these renders identically. It only separates
/// itself from its siblings on a sentence long enough to wrap, where the two
/// halves of the wrap disagree. [LyricContentAlign] is the control that moves
/// a line across the view.
enum LyricLineAlign { left, center, right, justify }

/// Which side of the view a sentence sits on.
///
/// This is the alignment a reader actually sees, because it is applied as a
/// translation of the painted line rather than inside it. The package resolves
/// it to an x-offset of 0, half the slack, or all of it; the three values here
/// are exactly the three it implements, since its fallback for anything else
/// collapses to the same offset as [start].
enum LyricContentAlign { start, center, end }

/// Which part of a sentence the anchor line is measured against.
///
/// `start` measures against the middle of the spoken text, `center` against
/// the middle of the whole line including any translation beneath it, and
/// `end` against the middle of that translation. It is also inert on a
/// sentence with no translation: the package reads these as `start` for such a
/// line regardless of what is stored here, so on a page where nothing was
/// rewritten for speech, no choice in this enum moves anything.
enum LyricAnchorAlign { start, center, end }

/// The reader's choices for how the TTS sentence list is laid out.
///
/// Only the four alignments, and each is a question the view already had a
/// silent answer to. They live in one object rather than as four loose fields
/// because they are one decision — a reader who left-aligns the sentences
/// wants the same edge for the sentence and for the anchor that parks it — and
/// because the values have to travel together to the view that uses them.
///
/// The defaults are what the view used before this existed: centred on all
/// three axes, which is what `LyricStyles.default1` ships and therefore what
/// every reader has been looking at.
@freezed
abstract class TtsLyricStyle with _$TtsLyricStyle {
  const factory TtsLyricStyle({
    @Default(LyricLineAlign.center)
    @JsonKey(unknownEnumValue: LyricLineAlign.center)
    LyricLineAlign lineAlign,
    @Default(LyricContentAlign.center)
    @JsonKey(unknownEnumValue: LyricContentAlign.center)
    LyricContentAlign contentAlign,
    @Default(LyricAnchorAlign.center)
    @JsonKey(unknownEnumValue: LyricAnchorAlign.center)
    LyricAnchorAlign selectionAnchorAlign,
    @Default(LyricAnchorAlign.center)
    @JsonKey(unknownEnumValue: LyricAnchorAlign.center)
    LyricAnchorAlign activeAnchorAlign,
  }) = _TtsLyricStyle;

  factory TtsLyricStyle.fromJson(Map<String, dynamic> json) =>
      _$TtsLyricStyleFromJson(json);
}
