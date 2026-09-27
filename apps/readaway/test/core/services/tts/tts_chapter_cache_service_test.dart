import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/tts/cache/tts_chapter_cache_service.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway_core/readaway_core.dart';

import 'tts_chapter_cache_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AppPathService>(),
  MockSpec<SettingsService>(),
])
void main() {
  late Directory tempDir;
  late Directory ttsCacheDir;
  late MockAppPathService mockPathService;
  late MockSettingsService mockSettingsService;
  late TtsChapterCacheService cacheService;

  const sampleVoice = TtsVoiceOption(
    id: 'vits-piper-en_US-amy-low',
    label: 'Amy',
    languageCode: 'en_US',
    engine: TtsEngineKind.sherpaOnnx,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tts_cache_test_');
    ttsCacheDir = Directory(p.join(tempDir.path, 'tts_cache'));
    await ttsCacheDir.create(recursive: true);

    mockPathService = MockAppPathService();
    mockSettingsService = MockSettingsService();

    when(mockPathService.getTtsAudioCacheDirectory())
        .thenAnswer((_) async => ttsCacheDir);
    when(mockSettingsService.settings).thenReturn(
      const Settings(
        globalViewSettings: GlobalViewSettings(
          ttsMaxCacheSizeMb: 10,
        ),
      ),
    );

    cacheService = TtsChapterCacheService(
      mockPathService,
      mockSettingsService,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TtsChapterCacheService', () {
    test('computes deterministic book key and text hash', () {
      final key1 = cacheService.computeBookKey('/path/to/book1.epub');
      final key2 = cacheService.computeBookKey('/path/to/book1.epub');
      final key3 = cacheService.computeBookKey('/path/to/book2.epub');

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));

      final hash1 = cacheService.computeTextHash('Hello world');
      final hash2 = cacheService.computeTextHash('Hello world');
      final hash3 = cacheService.computeTextHash('Different text');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
    });

    test('saves and retrieves chapter manifest correctly', () async {
      const bookPath = '/books/sample.epub';
      const chapterIdx = 1;
      final textHash = cacheService.computeTextHash('Sample chapter text content');
      final now = DateTime.now();

      final manifest = TtsChapterCacheManifest(
        chapterIndex: chapterIdx,
        textHash: textHash,
        voiceId: sampleVoice.id,
        speakerId: sampleVoice.sherpaSpeakerId ?? 0,
        configHash: cacheService.computeConfigHash(
          mockSettingsService.settings.globalViewSettings,
        ),
        createdAt: now,
        lastAccessedAt: now,
      );

      await cacheService.saveChapterManifest(
        bookPath: bookPath,
        chapterIndex: chapterIdx,
        voice: sampleVoice,
        manifest: manifest,
      );

      final loaded = await cacheService.getChapterManifest(
        bookPath: bookPath,
        chapterIndex: chapterIdx,
        voice: sampleVoice,
        textHash: textHash,
      );

      expect(loaded, isNotNull);
      expect(loaded!.chapterIndex, chapterIdx);
      expect(loaded.textHash, textHash);
      expect(loaded.voiceId, sampleVoice.id);
    });

    test('invalidates stale manifest when textHash mismatches', () async {
      const bookPath = '/books/sample.epub';
      const chapterIdx = 0;
      final oldHash = cacheService.computeTextHash('Old text');
      final newHash = cacheService.computeTextHash('Modified text');
      final now = DateTime.now();

      final manifest = TtsChapterCacheManifest(
        chapterIndex: chapterIdx,
        textHash: oldHash,
        voiceId: sampleVoice.id,
        configHash: cacheService.computeConfigHash(
          mockSettingsService.settings.globalViewSettings,
        ),
        createdAt: now,
        lastAccessedAt: now,
      );

      await cacheService.saveChapterManifest(
        bookPath: bookPath,
        chapterIndex: chapterIdx,
        voice: sampleVoice,
        manifest: manifest,
      );

      // Query with new text hash should return null and clear stale files
      final result = await cacheService.getChapterManifest(
        bookPath: bookPath,
        chapterIndex: chapterIdx,
        voice: sampleVoice,
        textHash: newHash,
      );

      expect(result, isNull);
    });

    test('validates chunk file existence and minimal length', () async {
      const bookPath = '/books/sample.epub';
      final file = await cacheService.getChunkFile(
        bookPath: bookPath,
        chapterIndex: 0,
        voice: sampleVoice,
        chunkIndex: 0,
      );

      expect(await cacheService.isChunkFileValid(file), false);

      // Create dummy file < 44 bytes
      await file.parent.create(recursive: true);
      await file.writeAsBytes(List.filled(10, 0));
      expect(await cacheService.isChunkFileValid(file), false);

      // Create dummy file > 44 bytes (valid WAV header placeholder)
      await file.writeAsBytes(List.filled(100, 0));
      expect(await cacheService.isChunkFileValid(file), true);
    });

    test('calculates total cache size and enforces LRU limit', () async {
      const bookPath1 = '/books/book1.epub';
      const bookPath2 = '/books/book2.epub';

      final file1 = await cacheService.getChunkFile(
        bookPath: bookPath1,
        chapterIndex: 0,
        voice: sampleVoice,
        chunkIndex: 0,
      );
      final file2 = await cacheService.getChunkFile(
        bookPath: bookPath2,
        chapterIndex: 0,
        voice: sampleVoice,
        chunkIndex: 0,
      );

      await file1.parent.create(recursive: true);
      await file2.parent.create(recursive: true);

      // Write 200 KB to book1 and 200 KB to book2
      await file1.writeAsBytes(List.filled(200 * 1024, 1));
      await file2.writeAsBytes(List.filled(200 * 1024, 2));

      // Save manifests with different access dates (book1 older, book2 newer)
      final manifest1 = TtsChapterCacheManifest(
        chapterIndex: 0,
        textHash: 'hash1',
        voiceId: sampleVoice.id,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        lastAccessedAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      final manifest2 = TtsChapterCacheManifest(
        chapterIndex: 0,
        textHash: 'hash2',
        voiceId: sampleVoice.id,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );

      await cacheService.saveChapterManifest(
        bookPath: bookPath1,
        chapterIndex: 0,
        voice: sampleVoice,
        manifest: manifest1,
      );
      await cacheService.saveChapterManifest(
        bookPath: bookPath2,
        chapterIndex: 0,
        voice: sampleVoice,
        manifest: manifest2,
      );

      final totalSize = await cacheService.calculateTotalCacheSizeBytes();
      expect(totalSize, greaterThanOrEqualTo(400 * 1024));

      // Enforce limit of 250 KB -> book1 (older) should be evicted
      await cacheService.enforceCacheLimit(250 * 1024);

      expect(await file1.exists(), false);
      expect(await file2.exists(), true);
    });

    test('clearBookCache removes all cached chapters for specific book', () async {
      const bookPath = '/books/target_book.epub';
      final file = await cacheService.getChunkFile(
        bookPath: bookPath,
        chapterIndex: 0,
        voice: sampleVoice,
        chunkIndex: 0,
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(List.filled(100, 0));

      expect(await file.exists(), true);
      await cacheService.clearBookCache(bookPath);
      expect(await file.exists(), false);
    });
  });
}
