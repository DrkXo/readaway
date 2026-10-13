import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/storage/drift/app_database.dart';
import 'package:readaway/src/core/services/storage/drift/daos/tts_dao.dart';
import 'package:readaway/src/core/services/tts/tts_model_store.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';

import '../../../helpers/test_helpers.dart';

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
  late TtsModelStore store;

  setUp(() {
    db = openTestDatabase();
    store = TtsModelStore(TtsDao(db));
  });

  tearDown(() {
    db.close();
  });

  test(
    'persists catalog, marks models downloaded and survives reload',
    () async {
      await store.init();

      await store.saveCatalog([_model]);

      final catalog = store.loadCatalog();
      expect(catalog.length, 1);
      expect(catalog.first.id, 'test-model-1');
      expect(catalog.first.type, SherpaTtsModelType.vits);
      expect(store.catalogTimestamp, isNotNull);

      await store.markDownloaded('test-model-1');
      expect(store.loadDownloadedIds().contains('test-model-1'), isTrue);

      // A fresh store hydrates the same state from the database.
      final reloaded = TtsModelStore(TtsDao(db));
      await reloaded.init();
      expect(reloaded.loadCatalog().map((m) => m.id), ['test-model-1']);
      expect(reloaded.byId('test-model-1')?.id, 'test-model-1');
      expect(reloaded.loadDownloadedIds(), {'test-model-1'});
      reloaded.dispose();

      final catalogRows = await db.select(db.ttsCatalogModels).get();
      expect(catalogRows, hasLength(1));
      expect(catalogRows.single.payload.id, 'test-model-1');
      final installedRows = await db.select(db.ttsInstalledModels).get();
      expect(installedRows, hasLength(1));
      expect(installedRows.single.payload.id, 'test-model-1');
    },
  );

  test('checksums round-trip through a reload', () async {
    await store.init();
    await store.saveChecksums({'a.tar.bz2': 'abc'});

    expect(store.checksumFor('a.tar.bz2'), 'abc');

    final reloaded = TtsModelStore(TtsDao(db));
    await reloaded.init();
    expect(reloaded.checksumFor('a.tar.bz2'), 'abc');
    reloaded.dispose();
  });

  test('removing installed models updates the index', () async {
    await store.init();
    await store.saveInstalledModel(_model);
    expect(store.loadDownloadedIds(), {'test-model-1'});

    await store.removeInstalledModel('test-model-1');

    expect(store.loadInstalledModels(), isEmpty);
    final rows = await db.select(db.ttsInstalledModels).get();
    expect(rows, isEmpty);
  });

  test('watchCatalog emits the current catalog then updates', () async {
    await store.init();
    final events = <List<SherpaTtsModelInfo>>[];
    final sub = store.watchCatalog().listen(events.add);

    await store.saveCatalog([_model]);
    await pumpEventQueue();

    // The stream opens with the current snapshot and re-emits on writes.
    expect(events.first, isEmpty);
    expect(events.last.map((m) => m.id), ['test-model-1']);
    await sub.cancel();
  });
}
