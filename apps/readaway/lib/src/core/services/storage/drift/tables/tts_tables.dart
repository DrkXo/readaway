import 'package:drift/drift.dart';

import '../converters/json_converters.dart';

/// Cached remote TTS catalog.
///
/// A separate table from [TtsInstalledModels] so a wholesale catalog refresh
/// can never touch installation metadata. The model metadata is a value object
/// consumed as a whole, so it is stored as a JSON [payload]; [sortIndex]
/// preserves the catalog's display order.
@DataClassName('TtsCatalogModelRow')
class TtsCatalogModels extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text().map(const TtsModelConverter())();
  IntColumn get sortIndex => integer()();
  IntColumn get syncedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Installed (downloaded) TTS models, keyed by model id.
@DataClassName('TtsInstalledModelRow')
class TtsInstalledModels extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text().map(const TtsModelConverter())();

  /// Milliseconds since epoch, mirroring `SherpaTtsModelInfo.installedAt`.
  IntColumn get installedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// sha256 of a release asset by file name.
@DataClassName('TtsChecksumRow')
class TtsChecksums extends Table {
  TextColumn get fileName => text()();
  TextColumn get sha256 => text()();

  @override
  Set<Column> get primaryKey => {fileName};
}

/// TTS bookkeeping (catalog sync timestamp, and similar scalars).
@DataClassName('TtsMetaRow')
class TtsMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
