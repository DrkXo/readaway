import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/services/audio/audio_player_service.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/tts/cache/tts_chapter_cache_service.dart';
import 'package:readaway/src/core/services/tts/controller/tts_controller_service.dart';
import 'package:readaway/src/core/services/tts/tts_chunker_service.dart';
import 'package:readaway/src/core/services/tts/tts_engine.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway_core/readaway_core.dart';
import 'package:rxdart/rxdart.dart';

import 'tts_controller_service_pipeline_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<TtsEngineRegistry>(),
  MockSpec<TtsEngine>(),
  MockSpec<AudioPlayerService>(),
  MockSpec<TtsChunkingService>(),
  MockSpec<SettingsService>(),
  MockSpec<TtsChapterCacheService>(),
])
void main() {
  late MockTtsEngineRegistry mockEngineRegistry;
  late MockTtsEngine mockEngine;
  late MockAudioPlayerService mockAudioPlayer;
  late MockTtsChunkingService mockChunkingService;
  late MockSettingsService mockSettingsService;
  late MockTtsChapterCacheService mockCacheService;
  late TtsControllerService controller;

  const sampleVoice = TtsVoiceOption(
    id: 'vits-piper-en_US-amy-low',
    label: 'Amy',
    languageCode: 'en_US',
    engine: TtsEngineKind.sherpaOnnx,
  );

  final sampleChunks = [
    const TtsChunk(
      id: '0:0:0',
      sectionIndex: 0,
      sentenceIndex: 0,
      text: 'First sentence.',
      spokenText: 'First sentence.',
      startOffset: 0,
      endOffset: 15,
      estimatedDurationMs: 1200,
    ),
    const TtsChunk(
      id: '0:1:16',
      sectionIndex: 0,
      sentenceIndex: 1,
      text: 'Second sentence.',
      spokenText: 'Second sentence.',
      startOffset: 16,
      endOffset: 32,
      estimatedDurationMs: 1400,
    ),
  ];

  setUp(() {
    mockEngineRegistry = MockTtsEngineRegistry();
    mockEngine = MockTtsEngine();
    mockAudioPlayer = MockAudioPlayerService();
    mockChunkingService = MockTtsChunkingService();
    mockSettingsService = MockSettingsService();
    mockCacheService = MockTtsChapterCacheService();

    when(mockSettingsService.settings).thenReturn(
      const Settings(
        globalViewSettings: GlobalViewSettings(
          ttsVoice: 'vits-piper-en_US-amy-low',
          ttsMaxCacheSizeMb: 500,
        ),
      ),
    );
    when(mockSettingsService.changes).thenAnswer((_) => const Stream.empty());

    when(mockEngineRegistry.getEngineForVoice(any)).thenReturn(mockEngine);
    when(mockEngineRegistry.getAllInstalledVoices())
        .thenAnswer((_) async => [sampleVoice]);
    when(mockEngine.initialize()).thenAnswer((_) async {});
    when(mockEngine.getAvailableVoices()).thenAnswer((_) async => [sampleVoice]);

    when(mockAudioPlayer.positionDataStream).thenAnswer(
      (_) => BehaviorSubject<PositionData>.seeded(
        const PositionData(Duration.zero, Duration.zero, Duration.zero),
      ),
    );
    when(mockAudioPlayer.sessionStateStream).thenAnswer(
      (_) => const Stream<PlayerState>.empty(),
    );
    when(mockAudioPlayer.currentIndexStream).thenAnswer(
      (_) => const Stream<int?>.empty(),
    );
    when(mockAudioPlayer.setPlaylist(any,
            initialIndex: anyNamed('initialIndex'),
            autoPlay: anyNamed('autoPlay')))
        .thenAnswer((_) async {});
    when(mockAudioPlayer.stopSession()).thenAnswer((_) async {});
    when(mockAudioPlayer.setSpeed(any)).thenAnswer((_) async {});
    when(mockAudioPlayer.setPitch(any)).thenAnswer((_) async {});

    when(mockChunkingService.start()).thenAnswer((_) async {});
    when(mockChunkingService.stop()).thenAnswer((_) async {});
    when(mockChunkingService.chunkText(any))
        .thenAnswer((_) async => sampleChunks);

    when(mockCacheService.computeTextHash(any)).thenReturn('hash_123');
    when(mockCacheService.computeConfigHash(any)).thenReturn('cfg_123');

    controller = TtsControllerService(
      mockEngineRegistry,
      mockAudioPlayer,
      mockChunkingService,
      mockSettingsService,
      mockCacheService,
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  group('TtsControllerService Pipeline with Chapter Cache', () {
    test('cache miss synthesizes chunk to file and saves manifest', () async {
      final fakeChunkFile0 = File('/tmp/test_chunk_0.wav');
      final fakeChunkFile1 = File('/tmp/test_chunk_1.wav');

      when(mockCacheService.getChapterManifest(
        bookPath: anyNamed('bookPath'),
        chapterIndex: anyNamed('chapterIndex'),
        voice: anyNamed('voice'),
        textHash: anyNamed('textHash'),
      )).thenAnswer((_) async => null);

      when(mockCacheService.getChunkFile(
        bookPath: anyNamed('bookPath'),
        chapterIndex: anyNamed('chapterIndex'),
        voice: anyNamed('voice'),
        chunkIndex: 0,
      )).thenAnswer((_) async => fakeChunkFile0);

      when(mockCacheService.getChunkFile(
        bookPath: anyNamed('bookPath'),
        chapterIndex: anyNamed('chapterIndex'),
        voice: anyNamed('voice'),
        chunkIndex: 1,
      )).thenAnswer((_) async => fakeChunkFile1);

      when(mockCacheService.isChunkFileValid(any)).thenAnswer((_) async => false);

      when(mockEngine.synthesizeToFile(
        text: anyNamed('text'),
        outputPath: anyNamed('outputPath'),
        voice: anyNamed('voice'),
        speed: anyNamed('speed'),
        pitch: anyNamed('pitch'),
        gapSec: anyNamed('gapSec'),
      )).thenAnswer(
        (inv) async => TtsSynthesisResult(
          file: File(inv.namedArguments[#outputPath] as String),
          duration: 1.5,
          waveform: const [0.1, 0.5, 0.8],
        ),
      );

      when(mockCacheService.saveChapterManifest(
        bookPath: anyNamed('bookPath'),
        chapterIndex: anyNamed('chapterIndex'),
        voice: anyNamed('voice'),
        manifest: anyNamed('manifest'),
      )).thenAnswer((_) async {});

      await controller.prepareForPlayback();
      await controller.playText(
        'First sentence. Second sentence.',
        bookPath: '/books/sample.epub',
        sectionIndex: 0,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify synthesizeToFile was called for chunk 0 and chunk 1
      verify(mockEngine.synthesizeToFile(
        text: 'First sentence.',
        outputPath: fakeChunkFile0.path,
        voice: sampleVoice,
        speed: 1.0,
        pitch: 1.0,
        gapSec: anyNamed('gapSec'),
      )).called(1);

      verify(mockEngine.synthesizeToFile(
        text: 'Second sentence.',
        outputPath: fakeChunkFile1.path,
        voice: sampleVoice,
        speed: 1.0,
        pitch: 1.0,
        gapSec: anyNamed('gapSec'),
      )).called(1);

      // Verify manifest was saved
      verify(mockCacheService.saveChapterManifest(
        bookPath: '/books/sample.epub',
        chapterIndex: 0,
        voice: sampleVoice,
        manifest: anyNamed('manifest'),
      )).called(greaterThanOrEqualTo(1));

      // Verify AudioPlayer setPlaylist was called with AudioSources
      verify(mockAudioPlayer.setPlaylist(any,
              initialIndex: 0, autoPlay: true))
          .called(1);
    });

    test('cache hit loads directly from file and bypasses engine synthesis', () async {
      final fakeChunkFile0 = File('/tmp/cached_chunk_0.wav');
      final fakeChunkFile1 = File('/tmp/cached_chunk_1.wav');

      final cachedManifest = TtsChapterCacheManifest(
        chapterIndex: 0,
        textHash: 'hash_123',
        voiceId: sampleVoice.id,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        chunks: const [
          TtsCachedChunk(
            chunkIndex: 0,
            fileName: 'cached_chunk_0.wav',
            startOffset: 0,
            endOffset: 15,
            durationSec: 1.2,
            waveform: [0.2, 0.6, 0.9],
          ),
          TtsCachedChunk(
            chunkIndex: 1,
            fileName: 'cached_chunk_1.wav',
            startOffset: 16,
            endOffset: 32,
            durationSec: 1.4,
            waveform: [0.3, 0.7, 0.8],
          ),
        ],
      );

      when(mockCacheService.getChapterManifest(
        bookPath: anyNamed('bookPath'),
        chapterIndex: anyNamed('chapterIndex'),
        voice: anyNamed('voice'),
        textHash: anyNamed('textHash'),
      )).thenAnswer((_) async => cachedManifest);

      when(mockCacheService.getChunkFile(
        bookPath: anyNamed('bookPath'),
        chapterIndex: anyNamed('chapterIndex'),
        voice: anyNamed('voice'),
        chunkIndex: 0,
      )).thenAnswer((_) async => fakeChunkFile0);

      when(mockCacheService.getChunkFile(
        bookPath: anyNamed('bookPath'),
        chapterIndex: anyNamed('chapterIndex'),
        voice: anyNamed('voice'),
        chunkIndex: 1,
      )).thenAnswer((_) async => fakeChunkFile1);

      // Mark chunks as valid in cache
      when(mockCacheService.isChunkFileValid(any)).thenAnswer((_) async => true);

      await controller.prepareForPlayback();
      await controller.playText(
        'First sentence. Second sentence.',
        bookPath: '/books/sample.epub',
        sectionIndex: 0,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Engine synthesis should NEVER be called on cache hit!
      verifyNever(mockEngine.synthesizeToFile(
        text: anyNamed('text'),
        outputPath: anyNamed('outputPath'),
        voice: anyNamed('voice'),
        speed: anyNamed('speed'),
        pitch: anyNamed('pitch'),
        gapSec: anyNamed('gapSec'),
      ));

      // AudioPlayer should receive playlist
      verify(mockAudioPlayer.setPlaylist(any,
              initialIndex: 0, autoPlay: true))
          .called(1);
    });
  });
}
