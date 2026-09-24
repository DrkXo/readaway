import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

Settings settingsFromJson(String str) => Settings.fromJson(json.decode(str));

String settingsToJson(Settings data) => json.encode(data.toJson());

@freezed
abstract class Settings with _$Settings {
  const factory Settings({
    @Default(1) int schemaVersion,
    @Default(1) int version,
    @Default(1) int migrationVersion,
    @Default(false) bool screenWakeLock,
    @Default([]) List<CustomFont> customFonts,
    @Default(GlobalViewSettings()) GlobalViewSettings globalViewSettings,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}

@freezed
abstract class CustomFont with _$CustomFont {
  const factory CustomFont({
    @Default('') String id,
    @Default('') String name,
    @Default('') String path,
  }) = _CustomFont;

  factory CustomFont.fromJson(Map<String, dynamic> json) =>
      _$CustomFontFromJson(json);
}

@freezed
abstract class GlobalViewSettings with _$GlobalViewSettings {
  const factory GlobalViewSettings({
    @Default('system') String theme,
    @Default('flexoki') String selectedScheme,
    @Default(0.3) double highlightOpacity,
    @Default(false) bool volumeKeysToFlip,
    @Default('slide') String pageTurnStyle,
    @Default(1.0) double ttsRate,
    @Default(1.0) double ttsPitch,
    String? ttsVoice,
    @Default('balanced') String ttsNarrationStyle,
    @Default(500) int ttsSentenceGap,
    @Default(1000) int ttsParagraphGap,
    @Default(0.2) double ttsSilenceScale,
    @Default(0.667) double ttsNoiseScale,
    @Default(0.8) double ttsNoiseScaleW,
    @Default(1.0) double ttsLengthScale,
    @Default(5) int ttsNumSteps,
    @Default(-1) int ttsSleepTimerMinutes,
  }) = _GlobalViewSettings;

  factory GlobalViewSettings.fromJson(Map<String, dynamic> json) =>
      _$GlobalViewSettingsFromJson(json);
}
