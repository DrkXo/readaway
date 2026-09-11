import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_preferences.freezed.dart';
part 'reader_preferences.g.dart';

enum ReaderPageTransition { none, fade, slide, sharedAxis, cover }

enum ReaderScrollDirection {
  horizontal,
  vertical,
}

/// The reading engine mode: publisher original design vs user-customized reflow.
enum ReaderEngineMode {
  /// Mode A: MuPDF native C Fitz rendering (100% publisher fidelity, vector zoom).
  publisherFidelity,

  /// Mode B: HyperRender pure flow layout (full user typography and theme customization).
  customFlow,
}

/// Whether a [ReaderPageTransition] is available for a given scroll direction.
extension ReaderPageTransitionSupport on ReaderPageTransition {
  /// The page-flip curl effect is inherently horizontal.
  bool isSupportedFor(ReaderScrollDirection direction) {
    return true;
  }
}

@freezed
abstract class ReaderPreferences with _$ReaderPreferences {
  const factory ReaderPreferences({
    @Default(ReaderEngineMode.customFlow)
    @JsonKey(unknownEnumValue: ReaderEngineMode.customFlow)
    ReaderEngineMode engineMode,
    String? fontFamily,
    @Default('Noto Serif') String serifFont,
    @Default('Noto Sans') String sansSerifFont,
    @Default('Fira Code') String monospaceFont,
    @Default('normal') String fontWeight,
    @Default(false) bool overrideFont,
    @Default(true) bool overrideLayout,
    @Default(false) bool overrideColor,
    @Default(16.0) double fontSize,
    @Default(1.5) double lineHeight,
    @Default(0.0) double letterSpacing,
    @Default(0.0) double wordSpacing,
    @Default(0.0) double textIndent,
    @Default(0.5) double paragraphMargin,
    @Default(true) bool fullJustification,
    @Default(16.0) double marginHorizontal,
    @Default(16.0) double marginTop,
    @Default(16.0) double marginBottom,
    @Default(true) bool pageSnap,
    @Default(ReaderScrollDirection.horizontal)
    ReaderScrollDirection scrollDirection,
    @Default(ReaderPageTransition.slide)
    @JsonKey(unknownEnumValue: ReaderPageTransition.slide)
    ReaderPageTransition pageTransition,
    @Default(0.0) double brightnessOverlay,
    @Default(0.0) double contrastOverlay,
    double? autoScrollSpeed,
    @Default(true) bool keepScreenOn,
    @Default(true) bool showStatusBar,
  }) = _ReaderPreferences;

  factory ReaderPreferences.fromJson(Map<String, dynamic> json) =>
      _$ReaderPreferencesFromJson(json);
}
