import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_preferences.freezed.dart';
part 'reader_preferences.g.dart';

enum ReaderPageTransition { none, fade, slide, sharedAxis, cover }

enum ReaderScrollDirection {
  horizontal,
  vertical,
}

/// Text alignment for reflowable content (CSS `text-align`).
enum ReaderTextAlign {
  left,
  center,
  right,
  justify,
}

/// Reading progress style in the footer.
enum ReaderProgressStyle {
  pageNumber,
  percentage,
  hidden,
}

/// Alignment position for the running header in the top margin.
enum ReaderHeaderAlignment {
  left,
  center,
  right,
}

/// Which built-in font family is used when no explicit [ReaderPreferences.fontFamily]
/// override is set.
enum ReaderDefaultFont {
  serif,
  sansSerif,
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
  const ReaderPreferences._();

  const factory ReaderPreferences({
    String? fontFamily,
    @Default('Noto Serif') String serifFont,
    @Default('Noto Sans') String sansSerifFont,
    @Default('Fira Code') String monospaceFont,
    @Default('Source Han Sans') String defaultCjkFont,
    @Default(ReaderDefaultFont.serif)
    @JsonKey(unknownEnumValue: ReaderDefaultFont.serif)
    ReaderDefaultFont defaultFont,
    @Default('normal') String fontWeight,
    @Default('') String userStylesheet,
    @Default(false) bool overrideFont,
    @Default(true) bool overrideLayout,
    @Default(false) bool overrideColor,
    @Default(16.0) double fontSize,
    @Default(0.0) double minimumFontSize,
    @Default(1.5) double lineHeight,
    @Default(0.0) double letterSpacing,
    @Default(0.0) double wordSpacing,
    @Default(0.0) double textIndent,
    @Default(0.5) double paragraphMargin,
    @Default(ReaderTextAlign.justify)
    @JsonKey(unknownEnumValue: ReaderTextAlign.justify)
    ReaderTextAlign textAlign,
    @Default(false) bool keepTextAlignment,
    @Default(16.0) double marginHorizontal,
    @Default(16.0) double marginTop,
    @Default(16.0) double marginBottom,
    @Default(true) bool pageSnap,
    @Default(ReaderScrollDirection.horizontal)
    ReaderScrollDirection scrollDirection,
    @Default(ReaderPageTransition.slide)
    @JsonKey(unknownEnumValue: ReaderPageTransition.slide)
    ReaderPageTransition pageTransition,
    @Default(ReaderScrollDirection.vertical)
    @JsonKey(unknownEnumValue: ReaderScrollDirection.vertical)
    ReaderScrollDirection nonReflowableScrollDirection,
    @Default(true) bool nonReflowablePageSnap,
    @Default(ReaderPageTransition.slide)
    @JsonKey(unknownEnumValue: ReaderPageTransition.slide)
    ReaderPageTransition nonReflowablePageTransition,
    @Default(0.0) double brightnessOverlay,
    @Default(0.0) double contrastOverlay,
    @Default(true) bool showStatusBar,
    @Default(true) bool showHeader,
    @Default(ReaderHeaderAlignment.left)
    @JsonKey(unknownEnumValue: ReaderHeaderAlignment.left)
    ReaderHeaderAlignment headerAlignment,
    @Default(11.0) double headerFontSize,
    @Default(true) bool showFooter,
    @Default(ReaderProgressStyle.pageNumber)
    @JsonKey(unknownEnumValue: ReaderProgressStyle.pageNumber)
    ReaderProgressStyle footerProgressStyle,
    @Default(true) bool showRemainingPages,
    @Default(false) bool showCurrentTime,
    @Default(false) bool showBatteryStatus,
    @Default(false) bool showFooterProgressBar,
    @Default(11.0) double footerFontSize,
  }) = _ReaderPreferences;

  factory ReaderPreferences.fromJson(Map<String, dynamic> json) =>
      _$ReaderPreferencesFromJson(json);

  static ReaderPreferences fromStoredJson(Map<String, dynamic> json) =>
      _$ReaderPreferencesFromJson(json);

  /// Returns the effective scroll direction for the given format reflowability.
  ReaderScrollDirection effectiveScrollDirection({required bool isReflowable}) =>
      isReflowable ? scrollDirection : nonReflowableScrollDirection;

  /// Returns the effective page snap option for the given format reflowability.
  bool effectivePageSnap({required bool isReflowable}) =>
      isReflowable ? pageSnap : nonReflowablePageSnap;

  /// Returns the effective page transition for the given format reflowability.
  ReaderPageTransition effectivePageTransition({required bool isReflowable}) =>
      isReflowable ? pageTransition : nonReflowablePageTransition;
}
