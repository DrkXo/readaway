import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_preferences.freezed.dart';
part 'reader_preferences.g.dart';

enum ReaderPageTransition {
  none,
  fade,
  slide,
  sharedAxis,
}

enum ReaderScrollDirection {
  horizontal,
  vertical,
}

enum ReaderThemeMode {
  light,
  dark,
  system,
}

@freezed
abstract class ReaderPreferences with _$ReaderPreferences {
  const factory ReaderPreferences({
    @Default('Roboto') String fontFamily,
    @Default(16.0) double fontSize,
    @Default(1.5) double lineHeight,
    @Default(0.0) double letterSpacing,
    @Default(16.0) double marginHorizontal,
    @Default(true) bool pageSnap,
    @Default(ReaderScrollDirection.horizontal)
    ReaderScrollDirection scrollDirection,
    @Default(ReaderPageTransition.slide) ReaderPageTransition pageTransition,
    @Default(0.0) double brightnessOverlay,
    @Default(0.0) double contrastOverlay,
    @Default(null) double? autoScrollSpeed,
    @Default(true) bool keepScreenOn,
    @Default(true) bool showStatusBar,
    @Default(ReaderThemeMode.system) ReaderThemeMode themeMode,
  }) = _ReaderPreferences;

  factory ReaderPreferences.fromJson(Map<String, dynamic> json) =>
      _$ReaderPreferencesFromJson(json);
}
