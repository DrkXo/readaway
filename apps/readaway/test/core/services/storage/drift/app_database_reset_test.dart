import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/storage/drift/app_database.dart';
import 'package:readaway/src/core/services/storage/drift/daos/documents_dao.dart';
import 'package:readaway/src/core/services/storage/drift/daos/reader_preferences_dao.dart';
import 'package:readaway/src/core/services/storage/drift/daos/settings_dao.dart';
import 'package:readaway/src/core/services/storage/drift/daos/tts_dao.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';

import '../../../../helpers/test_helpers.dart';

const _model = SherpaTtsModelInfo(
  id: 'test-model-1',
  displayName: 'Test Voice',
  languageCode: 'en',
  languageLabel: 'English',
  type: SherpaTtsModelType.vits,
  downloadUrl: 'https://example.com/test.tar.bz2',
  approxSizeMb: 15.0,
);

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() {
    db.close();
  });

  test(
    'resetStorage wipes every table and leaves the database writable',
    () async {
      final documentsDao = DocumentsDao(db);
      final settingsDao = SettingsDao(db);
      final prefsDao = ReaderPreferencesDao(db);
      final ttsDao = TtsDao(db);

      await documentsDao.upsertDocument(
        RecentDocument(
          path: '/books/a.epub',
          fileName: 'a.epub',
          title: 'A',
          dateAdded: DateTime(2025),
          lastOpened: DateTime(2025, 1, 2),
          fileSize: 42,
          format: 'epub',
          tags: const ['fiction'],
        ),
      );
      await settingsDao.put(const Settings());
      await prefsDao.put(
        scope: ReaderPreferencesDao.globalScope,
        ownerKind: 'global',
        ownerKey: ReaderPreferencesDao.globalOwnerKey,
        prefs: const ReaderPreferences(),
      );
      await ttsDao.saveCatalog([_model]);
      await ttsDao.saveInstalledModel(_model);
      await ttsDao.saveChecksums({'a.tar.bz2': 'abc'});

      // All seeded: one document (with a tag join row), settings, prefs, and
      // every TTS table.
      expect(await documentsDao.getRecentDocuments(), hasLength(1));
      expect(await db.select(db.documentTags).get(), hasLength(1));
      expect(await settingsDao.get(), isNotNull);
      expect(
        await prefsDao.get(
          scope: ReaderPreferencesDao.globalScope,
          ownerKey: ReaderPreferencesDao.globalOwnerKey,
        ),
        isNotNull,
      );
      expect(await ttsDao.loadCatalog(), hasLength(1));
      expect(await ttsDao.loadInstalledModels(), hasLength(1));
      expect(await ttsDao.loadChecksums(), hasLength(1));

      await db.resetStorage();

      expect(await documentsDao.getRecentDocuments(), isEmpty);
      expect(await db.select(db.documentTags).get(), isEmpty);
      expect(await settingsDao.get(), isNull);
      expect(
        await prefsDao.get(
          scope: ReaderPreferencesDao.globalScope,
          ownerKey: ReaderPreferencesDao.globalOwnerKey,
        ),
        isNull,
      );
      expect(await ttsDao.loadCatalog(), isEmpty);
      expect(await ttsDao.loadInstalledModels(), isEmpty);
      expect(await ttsDao.loadChecksums(), isEmpty);

      // The database remains fully usable after the reset.
      await settingsDao.put(const Settings());
      expect(await settingsDao.get(), isNotNull);
    },
  );
}
