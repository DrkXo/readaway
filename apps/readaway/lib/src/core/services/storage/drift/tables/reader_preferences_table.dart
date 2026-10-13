import 'package:drift/drift.dart';

import '../converters/json_converters.dart';

/// Reader preferences, keyed by scope and owner.
///
/// Reader preferences are a wide value object that is always read and written
/// whole and never queried by field, so the row stores it as a JSON [payload].
/// The identity columns stay relational because lookup and de-duplication
/// depend on them:
///
/// - global: [scope] `global`, [ownerKey] `''`
/// - per document: [ownerKind] `content`, [ownerKey] the content sha256, so the
///   preference follows unchanged bytes across moves and renames
/// - fallback: [ownerKind] `path`, [ownerKey] the document path, used when the
///   file cannot be hashed
@DataClassName('ReaderPreferenceEntry')
class ReaderPreferenceEntries extends Table {
  TextColumn get scope => text()();
  TextColumn get ownerKind => text()();
  TextColumn get ownerKey => text()();

  TextColumn get payload => text().map(const ReaderPreferencesConverter())();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {scope, ownerKey};
}
