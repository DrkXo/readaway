import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/models/ui_feedback.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/routes/routes.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/features/reader/presentation/bloc/tts/reader_tts_bloc.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../helpers/test_mocks.dart';

void main() {
  setUpAll(registerMockitoDummies);

  late MockReaderRepository mockReader;
  late MockReaderTtsRepository mockTts;
  late StreamController<TtsPlaybackEvent> playbackStateController;
  late StreamController<TtsChunk> chunkController;

  setUp(() {
    GetIt.I.registerSingleton<AppRoutes>(AppRoutes());

    mockReader = MockReaderRepository();
    mockTts = MockReaderTtsRepository();
    playbackStateController = StreamController<TtsPlaybackEvent>.broadcast();
    chunkController = StreamController<TtsChunk>.broadcast();

    when(mockTts.playbackState)
        .thenAnswer((_) => playbackStateController.stream);
    when(mockTts.currentChunk).thenAnswer((_) => chunkController.stream);
    when(mockTts.currentVoice).thenReturn(null);
    when(mockTts.availableVoices).thenReturn([]);
    when(mockTts.start()).thenAnswer((_) async {});
    when(mockTts.stop()).thenAnswer((_) async => const Success(null));
    when(
      mockTts.releaseResources(),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() async {
    await playbackStateController.close();
    await chunkController.close();
    await GetIt.I.reset();
  });

  ReaderTtsBloc buildBloc() => ReaderTtsBloc(
    readerRepository: mockReader,
    ttsRepository: mockTts,
  );

  group('ReaderTtsBloc initialization', () {
    test('initial state is inactive', () {
      final bloc = buildBloc();
      expect(bloc.state.ttsActive, isFalse);
      expect(bloc.state.ttsCurrentPage, isNull);
      expect(bloc.state.ttsSleepTimerRemaining, isNull);
      expect(bloc.state.ttsSpeechRange, isNull);
      expect(bloc.state.ttsTargetVirtualPage, isNull);
    });
  });

  group('ReaderTtsBloc sleep timer', () {
    blocTest<ReaderTtsBloc, ReaderTtsState>(
      'setSleepTimer sets the remaining duration and starts ticking',
      build: buildBloc,
      seed: () => const ReaderTtsState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) => bloc.add(
        const ReaderTtsEvent.setSleepTimer(Duration(minutes: 15)),
      ),
      expect: () => [
        const ReaderTtsState(
          ttsActive: true,
          ttsCurrentPage: 0,
          ttsSleepTimerRemaining: Duration(minutes: 15),
        ),
      ],
    );

    blocTest<ReaderTtsBloc, ReaderTtsState>(
      'sleepTimerTick decrements remaining time',
      build: buildBloc,
      seed: () => const ReaderTtsState(
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsSleepTimerRemaining: Duration(seconds: 10),
      ),
      act: (bloc) => bloc.add(const ReaderTtsEvent.sleepTimerTick()),
      expect: () => [
        const ReaderTtsState(
          ttsActive: true,
          ttsCurrentPage: 0,
          ttsSleepTimerRemaining: Duration(seconds: 9),
        ),
      ],
    );

    blocTest<ReaderTtsBloc, ReaderTtsState>(
      'sleepTimerFired stops playback and resets state',
      build: buildBloc,
      seed: () => const ReaderTtsState(
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsSleepTimerRemaining: Duration(seconds: 1),
      ),
      act: (bloc) => bloc.add(const ReaderTtsEvent.sleepTimerFired()),
      expect: () => [
        const ReaderTtsState(
          ttsActive: false,
          ttsCurrentPage: null,
          ttsSleepTimerRemaining: Duration(seconds: 1),
          ttsSpeechRange: null,
          ttsTargetVirtualPage: null,
        ),
      ],
      verify: (_) {
        verify(mockTts.releaseResources()).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('ReaderTtsBloc close & error', () {
    blocTest<ReaderTtsBloc, ReaderTtsState>(
      'close stops playback and resets state',
      build: buildBloc,
      seed: () => const ReaderTtsState(
        ttsActive: true,
        ttsCurrentPage: 1,
        ttsTargetVirtualPage: 3,
        ttsSleepTimerRemaining: Duration(minutes: 5),
      ),
      act: (bloc) => bloc.add(const ReaderTtsEvent.close()),
      expect: () => [
        const ReaderTtsState(
          ttsActive: false,
          ttsCurrentPage: null,
          ttsSleepTimerRemaining: null,
          ttsSpeechRange: null,
          ttsTargetVirtualPage: null,
        ),
      ],
      verify: (_) {
        verify(mockTts.releaseResources()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<ReaderTtsBloc, ReaderTtsState>(
      'errorOccurred stops playback and emits error feedback',
      build: buildBloc,
      seed: () => const ReaderTtsState(ttsActive: true, ttsCurrentPage: 0),
      act: (bloc) => bloc.add(
        const ReaderTtsEvent.errorOccurred('Engine failed to speak'),
      ),
      expect: () => [
        isA<ReaderTtsState>()
            .having((s) => s.ttsActive, 'ttsActive', false)
            .having((s) => s.ttsCurrentPage, 'ttsCurrentPage', isNull)
            .having(
              (s) => s.transientFeedback?.failure,
              'failure',
              isA<TtsSynthesisFailure>(),
            ),
      ],
    );

    blocTest<ReaderTtsBloc, ReaderTtsState>(
      'consumeFeedback clears transientFeedback',
      build: buildBloc,
      seed: () => ReaderTtsState(
        transientFeedback: UiFeedback(
          failure: const TtsSynthesisFailure('error'),
        ),
      ),
      act: (bloc) => bloc.add(const ReaderTtsEvent.consumeFeedback()),
      expect: () => [
        const ReaderTtsState(transientFeedback: null),
      ],
    );
  });
}
