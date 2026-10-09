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

/// Visual style of text selection handles/anchors in the reader.
enum ReaderAnchorStyle {
  /// Sleek teardrop pin with a stem pointing directly at the boundary.
  modernPin,

  /// Fine vertical caret stem with a rounded grab bulb.
  lollipop,

  /// Compact rounded capsule with grip cues.
  minimalPill,

  /// Refined native-style teardrop.
  classicTeardrop,
}

/// Rendering engine used for PDF documents.
enum PdfEngineMode {
  /// Hardware-accelerated vector PDFium engine via pdfrx.
  /// Features vector-sharp pinch zoom, native text selection, and search.
  vector,

  /// Fast snapshot engine supporting slide, cover, and transition animations.
  snapshot,
}

/// Reading progression direction for pages (relevant for Manga vs. Western comics).
enum ReaderReadingDirection {
  /// Left-to-right (Western books, comics, and standard documents).
  leftToRight,

  /// Right-to-left (Japanese manga).
  rightToLeft,
}

/// Page presentation mode for fixed-layout documents.
enum ReaderPageSpread {
  /// Single page always.
  single,

  /// Dual-page spread on wide screens / landscape orientation.
  auto,

  /// Always dual-page spread.
  dual,
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
    @Default(ReaderAnchorStyle.modernPin)
    @JsonKey(unknownEnumValue: ReaderAnchorStyle.modernPin)
    ReaderAnchorStyle selectionAnchorStyle,
    @Default(PdfEngineMode.vector)
    @JsonKey(unknownEnumValue: PdfEngineMode.vector)
    PdfEngineMode pdfEngineMode,
    @Default(ReaderReadingDirection.leftToRight)
    @JsonKey(unknownEnumValue: ReaderReadingDirection.leftToRight)
    ReaderReadingDirection readingDirection,
    @Default(ReaderPageSpread.auto)
    @JsonKey(unknownEnumValue: ReaderPageSpread.auto)
    ReaderPageSpread pageSpread,
  }) = _ReaderPreferences;

  factory ReaderPreferences.fromJson(Map<String, dynamic> json) =>
      _$ReaderPreferencesFromJson(json);

  static ReaderPreferences fromStoredJson(Map<String, dynamic> json) =>
      _$ReaderPreferencesFromJson(json);

  /// Whether reading progression is right-to-left (e.g. Manga).
  bool get isRtl => readingDirection == ReaderReadingDirection.rightToLeft;

  /// Whether the user's text alignment is applied on top of the book's own
  /// alignment.
  ///
  /// Only meaningful while [overrideLayout] is on: when it is off the book's
  /// layout wins, and when [keepTextAlignment] is on the book's own alignment
  /// is preserved instead.
  bool get appliesTextAlignment => overrideLayout && !keepTextAlignment;

  /// Returns the effective scroll direction for the given format reflowability.
  ReaderScrollDirection effectiveScrollDirection({
    required bool isReflowable,
  }) => isReflowable ? scrollDirection : nonReflowableScrollDirection;

  /// Returns the effective page snap option for the given format reflowability.
  bool effectivePageSnap({required bool isReflowable}) =>
      isReflowable ? pageSnap : nonReflowablePageSnap;

  /// Returns the effective page transition for the given format reflowability.
  ReaderPageTransition effectivePageTransition({required bool isReflowable}) =>
      isReflowable ? pageTransition : nonReflowablePageTransition;
}
