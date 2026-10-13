import 'package:drift/drift.dart';

import '../converters/json_converters.dart';

/// Application settings, stored as a single row.
///
/// Settings are a value object read and written whole and never queried by
/// field, so the row holds a JSON [payload] rather than one column per
/// preference.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  IntColumn get id => integer()();

  TextColumn get payload => text().map(const SettingsConverter())();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['CHECK (id = 1)'];
}
