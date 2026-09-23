import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/storage/hive/app_storage_service.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway/src/core/services/storage/hive/hive_boxes.dart';
import 'package:readaway/src/core/services/storage/hive/hive_config_service.dart';
import 'package:readaway/src/core/services/tts/tts_model_store.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/features/library/data/datasources/library_local_data_source.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/reader/data/repositories/reader_preferences_repository_impl.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

import '../../../../helpers/test_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late Directory tempDir;
  late MockAppPathService pathService;
  late HiveConfigService configService;
  late HiveBoxes hiveBoxes;
  late AppStorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    pathService = MockAppPathService();
    when(pathService.getHiveDirectory()).thenAnswer((_) async => tempDir);

    hiveBoxes = HiveBoxes();
    configService = HiveConfigService(pathService, hiveBoxes);
    storageService = AppStorageService(
      config: configService,
      boxes: hiveBoxes,
    );
    await storageService.init();
  });

  tearDown(() async {
    try {
      await storageService.dispose();
    } catch (_) {}
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppStorageService feature-scoped boxes', () {
    test('initializes and provides open boxes for all features', () {
      expect(storageService.settingsBox.isOpen, isTrue);
      expect(storageService.settingsBox.name, hiveBoxes.settings);

      expect(storageService.libraryBox.isOpen, isTrue);
      expect(storageService.libraryBox.name, hiveBoxes.library);

      expect(storageService.readerBox.isOpen, isTrue);
      expect(storageService.readerBox.name, hiveBoxes.reader);

      expect(storageService.ttsBox.isOpen, isTrue);
      expect(storageService.ttsBox.name, hiveBoxes.tts);
    });

    test('settings service persists in settingsBox', () async {
      final service = SettingsService(storage: storageService);
      await service.init();

      const newSettings = Settings(screenWakeLock: true);
      await service.save(newSettings);

      expect(service.settings.screenWakeLock, isTrue);
      expect(storageService.settingsBox.containsKey('app_settings'), isTrue);
      expect(storageService.settingsBox.get('app_settings')?.screenWakeLock, isTrue);
    });

    test('library data source persists in libraryBox directly by path', () async {
      final dataSource = LibraryLocalDataSource(storageService);
      final doc = RecentDocument(
        path: '/path/to/doc.epub',
        fileName: 'doc.epub',
        title: 'Doc Title',
        dateAdded: DateTime(2025),
        lastOpened: DateTime(2025),
        fileSize: 1024,
        format: 'epub',
      );

      await dataSource.saveRecentDocument(doc);
      final list = await dataSource.getRecentDocuments();

      expect(list.length, 1);
      expect(list.first.path, '/path/to/doc.epub');
      expect(
        storageService.libraryBox.containsKey('/path/to/doc.epub'),
        isTrue,
      );
      expect(
        storageService.libraryBox.get('/path/to/doc.epub')?.title,
        'Doc Title',
      );
    });

    test('reader preferences repository persists in readerBox', () async {
      final repo = ReaderPreferencesRepositoryImpl(storageService);

      const prefs = ReaderPreferences(fontSize: 22.0);
      final saveResult = await repo.saveGlobalPreferences(prefs);
      expect(saveResult.isSuccess, isTrue);

      final readResult = await repo.getGlobalPreferences();
      expect(readResult.dataOrNull?.fontSize, 22.0);

      const docPrefs = ReaderPreferences(fontSize: 28.0);
      await repo.saveDocumentPreferences('/path/to/book.epub', docPrefs);

      final docResult =
          await repo.getDocumentPreferences('/path/to/book.epub');
      expect(docResult.dataOrNull?.fontSize, 28.0);

      expect(storageService.readerBox.containsKey('reader_global'), isTrue);
      expect(
        storageService.readerBox.containsKey('reader_doc_/path/to/book.epub'),
        isTrue,
      );
      expect(
        storageService.readerBox.get('reader_doc_/path/to/book.epub')?.fontSize,
        28.0,
      );
    });

    test('tts model store persists in ttsBox', () async {
      final ttsStore = TtsModelStore(storage: storageService);
      const model = SherpaTtsModelInfo(
        id: 'test-model-1',
        displayName: 'Test Voice',
        languageCode: 'en',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: 'https://example.com/test.tar.bz2',
        approxSizeMb: 15.0,
      );

      await ttsStore.saveCatalog([model]);

      final catalog = ttsStore.loadCatalog();
      expect(catalog.length, 1);
      expect(catalog.first.id, 'test-model-1');
      expect(catalog.first.type, SherpaTtsModelType.vits);

      await ttsStore.markDownloaded('test-model-1');
      expect(ttsStore.loadDownloadedIds().contains('test-model-1'), isTrue);

      expect(storageService.ttsBox.containsKey('tts_model_catalog'), isTrue);
    });

    test('resetStorage deletes all feature box files', () async {
      await storageService.settingsBox.put('app_settings', const Settings());
      await storageService.libraryBox.put(
        '/p',
        RecentDocument(
          path: '/p',
          fileName: 'f',
          title: 't',
          dateAdded: DateTime(2025),
          lastOpened: DateTime(2025),
          fileSize: 10,
          format: 'epub',
        ),
      );
      await storageService.readerBox.put('reader_global', const ReaderPreferences());
      await storageService.ttsBox.put('k4', 'v4');

      await storageService.resetStorage();

      final files = await configService.getAllBoxFiles();
      for (final file in files) {
        expect(await file.exists(), isFalse);
      }
    });
  });
}
