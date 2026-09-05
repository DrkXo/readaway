import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_preferences.freezed.dart';
part 'reader_preferences.g.dart';

enum ReaderPageTransition {
  none,
  fade,
  slide,
  sharedAxis,
  cover,
  curl,
}

enum ReaderScrollDirection {
  horizontal,
  vertical,
}

@freezed
abstract class ReaderPreferences with _$ReaderPreferences {
  const factory ReaderPreferences({
    String? fontFamily,
    @Default('Noto Serif') String serifFont,
    @Default('Noto Sans') String sansSerifFont,
    @Default('Fira Code') String monospaceFont,
    @Default('normal') String fontWeight,
    @Default(false) bool overrideFont,
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
    @Default(ReaderPageTransition.sharedAxis)
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
