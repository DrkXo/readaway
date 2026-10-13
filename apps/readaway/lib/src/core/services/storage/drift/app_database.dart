import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

// Imported so the code generated for the converted columns (settings, reader
// preferences, TTS models) resolves in this library.
import '../../../../features/reader/domain/entity/reader_preferences.dart';
import '../../../../features/settings/domain/entity/settings.dart';
import '../../tts/tts_models.dart';
import 'connection/connection.dart';
import 'converters/json_converters.dart';
import 'tables/app_meta_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/documents_table.dart';
import 'tables/reader_notes_table.dart';
import 'tables/reader_preferences_table.dart';
import 'tables/tts_tables.dart';

part 'app_database.g.dart';

/// The application's SQLite database.
///
/// One schema, opened lazily through the platform connection. Domain entities
/// are mapped in the DAOs, so nothing below the data layer sees drift types.
@DriftDatabase(
  tables: [
    AppMeta,
    Documents,
    DocumentTags,
    ReaderNotes,
    ReaderPreferenceEntries,
    AppSettings,
    TtsCatalogModels,
    TtsInstalledModels,
    TtsChecksums,
    TtsMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  final int _schemaVersionStored;

  /// Test constructor: takes an explicit executor (typically in-memory).
  AppDatabase(super.executor, {int schemaVersion = 1})
    : _schemaVersionStored = schemaVersion;

  /// Opens the production database using the platform connection.
  AppDatabase.open({int schemaVersion = 1})
    : _schemaVersionStored = schemaVersion,
      super(openAppConnection());

  @override
  int get schemaVersion => _schemaVersionStored;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // No migrations are implemented yet (schemaVersion == 1).
      // Fresh installs use [onCreate] only; [onUpgrade] runs only when an
      // existing database at version `from` is opened with schemaVersion `to`.
      if (to <= from) {
        // No change (or downgrade) — do nothing.
        return;
      }

      // Forward migration requested but not implemented. Fail explicitly so we
      // never silently open a mismatched schema.
      throw UnsupportedError(
        'Database migration from v$from to v$to is not implemented yet.',
      );
    },

    beforeOpen: (details) async {
      // SQLite disables foreign keys by default. Enabling them here (rather
      // than in a native-only setup callback) also turns them on for the web
      // database, whose connection cannot run a setup callback.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Empties every table and reclaims the freed space with `VACUUM`.
  ///
  /// This is the drift replacement for the removed
  /// `AppStorageService.resetStorage`: readers, preferences, settings and the
  /// TTS index are all wiped while the schema (and this database) stays
  /// usable. Child rows are deleted before parents so the operation is valid
  /// with foreign keys enabled, and `VACUUM` runs outside the transaction
  /// (SQLite forbids it inside one).
  Future<void> resetStorage() async {
    await transaction(() async {
      await delete(documentTags).go();
      await delete(documents).go();
      await delete(readerNotes).go();
      await delete(readerPreferenceEntries).go();
      await delete(appSettings).go();
      await delete(ttsCatalogModels).go();
      await delete(ttsInstalledModels).go();
      await delete(ttsChecksums).go();
      await delete(ttsMeta).go();
      await delete(appMeta).go();
    });
    await customStatement('VACUUM');
  }

  @disposeMethod
  Future<void> closeDatabase() => close();
}
