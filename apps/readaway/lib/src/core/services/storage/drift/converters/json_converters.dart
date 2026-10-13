import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../../features/reader/domain/entity/reader_preferences.dart';
import '../../../../../features/settings/domain/entity/settings.dart';
import '../../../tts/tts_models.dart';

/// Maps a reader-preferences value object to its JSON representation.
///
/// Used for columns whose value is always read and written whole and never
/// queried by field, so the stored shape is the serialized object.
class ReaderPreferencesConverter
    extends TypeConverter<ReaderPreferences, String> {
  const ReaderPreferencesConverter();

  @override
  ReaderPreferences fromSql(String fromDb) =>
      ReaderPreferences.fromJson(jsonDecode(fromDb) as Map<String, dynamic>);

  @override
  String toSql(ReaderPreferences value) => jsonEncode(value.toJson());
}

/// Maps the application-settings value object to its JSON representation.
class SettingsConverter extends TypeConverter<Settings, String> {
  const SettingsConverter();

  @override
  Settings fromSql(String fromDb) =>
      Settings.fromJson(jsonDecode(fromDb) as Map<String, dynamic>);

  @override
  String toSql(Settings value) => jsonEncode(value.toJson());
}

/// Maps a TTS model descriptor to its JSON representation.
class TtsModelConverter extends TypeConverter<SherpaTtsModelInfo, String> {
  const TtsModelConverter();

  @override
  SherpaTtsModelInfo fromSql(String fromDb) =>
      SherpaTtsModelInfo.fromJson(jsonDecode(fromDb) as Map<String, dynamic>);

  @override
  String toSql(SherpaTtsModelInfo value) => jsonEncode(value.toJson());
}
