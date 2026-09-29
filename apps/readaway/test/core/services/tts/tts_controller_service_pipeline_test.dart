import 'dart:async';
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

  /// Hoisted so a test can drive the player's position and observe the
  /// derived page-wide position that comes out of it.
  late BehaviorSubject<PositionData> positionData;

  /// Hoisted for the same reason: the controller reads the current chunk
  /// index off this to place a position on the page-wide axis.
  late StreamController<int?> playerIndex;

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
    positionData = BehaviorSubject<PositionData>.seeded(
      const PositionData(Duration.zero, Duration.zero, Duration.zero),
    );
    playerIndex = StreamController<int?>.broadcast();

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
    when(mockEngine.getAvailableVoices())
        .thenAnswer((_) async => [sampleVoice]);

    when(mockAudioPlayer.positionDataStream).thenAnswer((_) => positionData);
    when(mockAudioPlayer.sessionStateStream).thenAnswer(
      (_) => const Stream<PlayerState>.empty(),
    );
    when(mockAudioPlayer.currentIndexStream)
        .thenAnswer((_) => playerIndex.stream);
    when(
      mockAudioPlayer.setPlaylist(
        any,
        initialIndex: anyNamed('initialIndex'),
        autoPlay: anyNamed('autoPlay'),
      ),
    ).thenAnswer((_) async {});
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
    await playerIndex.close();
    await positionData.close();
    await controller.dispose();
  });

  group('TtsControllerService Pipeline with Chapter Cache', () {
    test('cache miss synthesizes chunk to file and saves manifest', () async {
      final fakeChunkFile0 = File('/tmp/test_chunk_0.wav');
      final fakeChunkFile1 = File('/tmp/test_chunk_1.wav');

      when(
        mockCacheService.getChapterManifest(
          bookPath: anyNamed('bookPath'),
          chapterIndex: anyNamed('chapterIndex'),
          voice: anyNamed('voice'),
          textHash: anyNamed('textHash'),
        ),
      ).thenAnswer((_) async => null);

      when(
        mockCacheService.getChunkFile(
          bookPath: anyNamed('bookPath'),
          chapterIndex: anyNamed('chapterIndex'),
          voice: anyNamed('voice'),
          chunkIndex: 0,
        ),
      ).thenAnswer((_) async => fakeChunkFile0);

      when(
        mockCacheService.getChunkFile(
          bookPath: anyNamed('bookPath'),
          chapterIndex: anyNamed('chapterIndex'),
          voice: anyNamed('voice'),
          chunkIndex: 1,
        ),
      ).thenAnswer((_) async => fakeChunkFile1);

      when(mockCacheService.isChunkFileValid(any))
          .thenAnswer((_) async => false);

      when(
        mockEngine.synthesizeToFile(
          text: anyNamed('text'),
          outputPath: anyNamed('outputPath'),
          voice: anyNamed('voice'),
          speed: anyNamed('speed'),
          pitch: anyNamed('pitch'),
          gapSec: anyNamed('gapSec'),
        ),
      ).thenAnswer(
        (inv) async => TtsSynthesisResult(
          file: File(inv.namedArguments[#outputPath] as String),
          duration: 1.5,
          waveform: const [0.1, 0.5, 0.8],
        ),
      );

      when(
        mockCacheService.saveChapterManifest(
          bookPath: anyNamed('bookPath'),
          chapterIndex: anyNamed('chapterIndex'),
          voice: anyNamed('voice'),
          manifest: anyNamed('manifest'),
        ),
      ).thenAnswer((_) async {});

      await controller.prepareForPlayback();
      await controller.playText(
        'First sentence. Second sentence.',
        bookPath: '/books/sample.epub',
        sectionIndex: 0,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify synthesizeToFile was called for chunk 0 and chunk 1
      verify(
        mockEngine.synthesizeToFile(
          text: 'First sentence.',
          outputPath: fakeChunkFile0.path,
          voice: sampleVoice,
          speed: 1.0,
          pitch: 1.0,
          gapSec: anyNamed('gapSec'),
        ),
      ).called(1);

      verify(
        mockEngine.synthesizeToFile(
          text: 'Second sentence.',
          outputPath: fakeChunkFile1.path,
          voice: sampleVoice,
          speed: 1.0,
          pitch: 1.0,
          gapSec: anyNamed('gapSec'),
        ),
      ).called(1);

      // Verify manifest was saved
      verify(
        mockCacheService.saveChapterManifest(
          bookPath: '/books/sample.epub',
          chapterIndex: 0,
          voice: sampleVoice,
          manifest: anyNamed('manifest'),
        ),
      ).called(greaterThanOrEqualTo(1));

      // Verify AudioPlayer setPlaylist was called with AudioSources
      verify(mockAudioPlayer.setPlaylist(any, initialIndex: 0, autoPlay: true))
          .called(1);
    });

    test(
      'cache hit loads directly from file and bypasses engine synthesis',
      () async {
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

        when(
          mockCacheService.getChapterManifest(
            bookPath: anyNamed('bookPath'),
            chapterIndex: anyNamed('chapterIndex'),
            voice: anyNamed('voice'),
            textHash: anyNamed('textHash'),
          ),
        ).thenAnswer((_) async => cachedManifest);

        when(
          mockCacheService.getChunkFile(
            bookPath: anyNamed('bookPath'),
            chapterIndex: anyNamed('chapterIndex'),
            voice: anyNamed('voice'),
            chunkIndex: 0,
          ),
        ).thenAnswer((_) async => fakeChunkFile0);

        when(
          mockCacheService.getChunkFile(
            bookPath: anyNamed('bookPath'),
            chapterIndex: anyNamed('chapterIndex'),
            voice: anyNamed('voice'),
            chunkIndex: 1,
          ),
        ).thenAnswer((_) async => fakeChunkFile1);

        // Mark chunks as valid in cache
        when(mockCacheService.isChunkFileValid(any))
            .thenAnswer((_) async => true);

        await controller.prepareForPlayback();
        await controller.playText(
          'First sentence. Second sentence.',
          bookPath: '/books/sample.epub',
          sectionIndex: 0,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Engine synthesis should NEVER be called on cache hit!
        verifyNever(
          mockEngine.synthesizeToFile(
            text: anyNamed('text'),
            outputPath: anyNamed('outputPath'),
            voice: anyNamed('voice'),
            speed: anyNamed('speed'),
            pitch: anyNamed('pitch'),
            gapSec: anyNamed('gapSec'),
          ),
        );

        // AudioPlayer should receive playlist
        verify(
          mockAudioPlayer.setPlaylist(any, initialIndex: 0, autoPlay: true),
        ).called(1);
      },
    );
  });

  group('TtsControllerService page timeline', () {
    /// Four chunks, so synthesis runs past the two-chunk pre-buffer and the
    /// axis is observed growing rather than appearing complete at once.
    final fourChunks = List.generate(
      4,
      (i) => TtsChunk(
        id: '0:$i:0',
        sectionIndex: 0,
        sentenceIndex: i,
        text: 'Sentence $i.',
        spokenText: 'Sentence $i.',
        startOffset: i * 16,
        endOffset: i * 16 + 15,
        estimatedDurationMs: 1000,
      ),
    );

    /// A manifest whose measured durations are known up front, as it would be
    /// on a second visit to an already-synthesized page.
    TtsChapterCacheManifest cachedManifest(List<double> durations) {
      final now = DateTime(2026, 1, 1);
      return durations.asMap().entries.fold(
        TtsChapterCacheManifest(
          chapterIndex: 0,
          textHash: 'hash_123',
          voiceId: sampleVoice.id,
          createdAt: now,
          lastAccessedAt: now,
        ),
        (acc, e) => acc.withChunk(
          TtsCachedChunk(
            chunkIndex: e.key,
            fileName: 'chunk_${e.key}.wav',
            startOffset: 0,
            endOffset: 10,
            durationSec: e.value,
          ),
        ),
      );
    }

    void stubManifest(TtsChapterCacheManifest? manifest) {
      when(
        mockCacheService.getChapterManifest(
          bookPath: anyNamed('bookPath'),
          chapterIndex: anyNamed('chapterIndex'),
          voice: anyNamed('voice'),
          textHash: anyNamed('textHash'),
        ),
      ).thenAnswer((_) async => manifest);
    }

    /// Chunk file paths and manifest persistence, with cache validity left to
    /// each test: a cache hit fills the axis from the manifest, a cache miss
    /// fills it from synthesis, and conflating the two hides both.
    void stubChunkFiles() {
      when(
        mockCacheService.getChunkFile(
          bookPath: anyNamed('bookPath'),
          chapterIndex: anyNamed('chapterIndex'),
          voice: anyNamed('voice'),
          chunkIndex: anyNamed('chunkIndex'),
        ),
      ).thenAnswer(
        (inv) async =>
            File('/tmp/tl_chunk_${inv.namedArguments[#chunkIndex]}.wav'),
      );
      when(
        mockCacheService.saveChapterManifest(
          bookPath: anyNamed('bookPath'),
          chapterIndex: anyNamed('chapterIndex'),
          voice: anyNamed('voice'),
          manifest: anyNamed('manifest'),
        ),
      ).thenAnswer((_) async {});
    }

    void stubCachedFiles() {
      stubChunkFiles();
      when(mockCacheService.isChunkFileValid(any))
          .thenAnswer((_) async => true);
    }

    void stubCacheMisses() {
      stubChunkFiles();
      when(mockCacheService.isChunkFileValid(any))
          .thenAnswer((_) async => false);
    }

    /// Polls until the axis satisfies [predicate], so tests assert on state
    /// rather than on a sleep that happens to be long enough.
    Future<TtsTimeline> waitForTimeline(
      bool Function(TtsTimeline) predicate,
    ) async {
      for (var i = 0; i < 100; i++) {
        final timeline = controller.timeline;
        if (timeline != null && predicate(timeline)) return timeline;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail(
        'timeline never satisfied the condition; last: ${controller.timeline}',
      );
    }

    /// Polls until [emitted] holds [count] non-null axis emissions.
    ///
    /// [controller].timeline is a field and [timelineStream] is a subject, so
    /// polling the field and cancelling the subscription can race — the field
    /// is already up to date while the stream delivery is still queued.
    Future<void> waitForMeasuredEmissions(
      List<TtsTimeline?> emitted,
      int count,
    ) async {
      for (var i = 0; i < 100; i++) {
        if (emitted.whereType<TtsTimeline>().length >= count) return;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('expected $count measured emissions, got $emitted');
    }

    test('is null before any chunk has a measured duration', () {
      expect(controller.timeline, isNull);
    });

    test(
      'is complete immediately from a cached manifest, before synthesis',
      () async {
        stubManifest(cachedManifest(const [1.2, 1.4, 0.9, 0.6]));
        stubCachedFiles();
        when(mockChunkingService.chunkText(any))
            .thenAnswer((_) async => fourChunks);

        await controller.prepareForPlayback();
        await controller.playText('text', bookPath: '/b.epub', sectionIndex: 0);

        final timeline = await waitForTimeline((t) => t.length == 4);
        expect(timeline.startOf(1), const Duration(milliseconds: 1200));
        expect(timeline.startOf(2), const Duration(milliseconds: 2600));
        expect(timeline.total, const Duration(milliseconds: 4100));
        verifyNever(
          mockEngine.synthesizeToFile(
            text: anyNamed('text'),
            outputPath: anyNamed('outputPath'),
            voice: anyNamed('voice'),
            speed: anyNamed('speed'),
            pitch: anyNamed('pitch'),
            gapSec: anyNamed('gapSec'),
          ),
        );
      },
    );

    test(
      'grows one chunk at a time as synthesis measures each sentence',
      () async {
        stubManifest(null);
        stubCacheMisses();
        when(mockChunkingService.chunkText(any))
            .thenAnswer((_) async => fourChunks);
        when(
          mockEngine.synthesizeToFile(
            text: anyNamed('text'),
            outputPath: anyNamed('outputPath'),
            voice: anyNamed('voice'),
            speed: anyNamed('speed'),
            pitch: anyNamed('pitch'),
            gapSec: anyNamed('gapSec'),
          ),
        ).thenAnswer(
          (inv) async => TtsSynthesisResult(
            file: File(inv.namedArguments[#outputPath] as String),
            duration: 0.5,
            waveform: const [0.1, 0.5],
          ),
        );

        final emitted = <TtsTimeline?>[];
        final sub = controller.timelineStream.listen(emitted.add);

        await controller.prepareForPlayback();
        await controller.playText('text', bookPath: '/b.epub', sectionIndex: 0);
        await waitForTimeline((t) => t.length == 4);
        await waitForMeasuredEmissions(emitted, 4);
        await sub.cancel();

        // A null leading emission, then strictly growing lengths. A repeated
        // length would mean an unchanged axis was republished, which would make
        // a lyric view rebuild and jump back to the top mid-sentence.
        expect(emitted.first, isNull);
        expect(
          emitted.map((t) => t?.length).whereType<int>().toList(),
          [1, 2, 3, 4],
          reason: 'axis must advance one measured chunk at a time',
        );
        expect(controller.timeline!.total, const Duration(milliseconds: 2000));
      },
    );

    test('stops at a skipped chunk instead of shifting later boundaries', () async {
      // An empty utterance is never synthesized, so chunk 1 never gets a
      // measured duration and every boundary after it is unknowable.
      stubManifest(null);
      stubCacheMisses();
      final withHole = [
        fourChunks[0],
        fourChunks[1].copyWith(text: '  ', spokenText: '  '),
        fourChunks[2],
        fourChunks[3],
      ];
      when(mockChunkingService.chunkText(any))
          .thenAnswer((_) async => withHole);
      when(
        mockEngine.synthesizeToFile(
          text: anyNamed('text'),
          outputPath: anyNamed('outputPath'),
          voice: anyNamed('voice'),
          speed: anyNamed('speed'),
          pitch: anyNamed('pitch'),
          gapSec: anyNamed('gapSec'),
        ),
      ).thenAnswer(
        (inv) async => TtsSynthesisResult(
          file: File(inv.namedArguments[#outputPath] as String),
          duration: 0.5,
          waveform: const [0.1, 0.5],
        ),
      );

      await controller.prepareForPlayback();
      await controller.playText('text', bookPath: '/b.epub', sectionIndex: 0);
      final timeline = await waitForTimeline((t) => t.length == 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      // Chunks 2 and 3 are synthesized and measured, but the axis must not
      // grow past the hole: their real start times depend on the missing audio.
      expect(controller.timeline!.length, 1);
      expect(timeline.total, const Duration(milliseconds: 500));
    });

    test('a stale axis does not survive a page change', () async {
      stubManifest(cachedManifest(const [1.2, 1.4, 0.9, 0.6]));
      stubCachedFiles();
      when(mockChunkingService.chunkText(any))
          .thenAnswer((_) async => fourChunks);

      await controller.prepareForPlayback();
      await controller.playText(
        'page one',
        bookPath: '/b.epub',
        sectionIndex: 0,
      );
      await waitForTimeline((t) => t.length == 4);

      // Second page: nothing measured yet. The axis must report nothing rather
      // than the previous page's four sentences, which would pair page one's
      // timings with page two's text.
      stubManifest(null);
      stubCacheMisses();
      when(mockChunkingService.chunkText(any))
          .thenAnswer((_) async => sampleChunks);
      when(
        mockEngine.synthesizeToFile(
          text: anyNamed('text'),
          outputPath: anyNamed('outputPath'),
          voice: anyNamed('voice'),
          speed: anyNamed('speed'),
          pitch: anyNamed('pitch'),
          gapSec: anyNamed('gapSec'),
        ),
      ).thenAnswer(
        (inv) async => TtsSynthesisResult(
          file: File(inv.namedArguments[#outputPath] as String),
          duration: 0.25,
          waveform: const [0.1],
        ),
      );

      final emitted = <TtsTimeline?>[];
      final sub = controller.timelineStream.listen(emitted.add);

      await controller.playText(
        'page two',
        bookPath: '/b.epub',
        sectionIndex: 1,
      );
      await waitForTimeline((t) => t.length == 2);
      await waitForMeasuredEmissions(emitted, 2);
      await sub.cancel();

      // Subscribing replays the current axis, which still describes page one.
      // Everything after that replay must belong to page two, and must start
      // from nothing rather than continuing where page one stopped.
      final afterReplay = emitted.skip(1).toList();
      expect(
        afterReplay.first,
        isNull,
        reason: 'stale axis must be dropped as soon as the page changes',
      );
      expect(
        afterReplay.map((t) => t?.length).whereType<int>().toList(),
        [1, 2],
        reason:
            'the new page rebuilds the axis from zero rather than '
            'continuing the previous page at four sentences',
      );
      expect(controller.timeline!.total, const Duration(milliseconds: 500));
    });

    test('global position is the chunk start plus the offset within it', () async {
      stubManifest(cachedManifest(const [1.2, 1.4, 0.9, 0.6]));
      stubCachedFiles();
      when(mockChunkingService.chunkText(any))
          .thenAnswer((_) async => fourChunks);

      await controller.prepareForPlayback();
      await controller.playText('text', bookPath: '/b.epub', sectionIndex: 0);
      await waitForTimeline((t) => t.length == 4);

      // start() is what wires the player's current index into the controller.
      controller.start();
      final global = <Duration>[];
      final sub = controller.globalPositionStream.listen(global.add);

      // Playback moves to the second chunk. Its start on the page-wide axis is
      // 1.2s in, not zero.
      playerIndex.add(1);
      positionData.add(
        const PositionData(
          Duration(milliseconds: 300),
          Duration(milliseconds: 300),
          Duration(milliseconds: 1400),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(global.last, const Duration(milliseconds: 1500));
      await sub.cancel();
    });

    test('global position is zero while nothing has been measured', () async {
      final global = <Duration>[];
      final sub = controller.globalPositionStream.listen(global.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(global, isNotEmpty);
      expect(global.every((d) => d == Duration.zero), isTrue);
      await sub.cancel();
    });
  });
}
