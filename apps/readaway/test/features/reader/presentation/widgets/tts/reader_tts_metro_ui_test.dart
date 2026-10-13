import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/tts/reader_tts_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/live_speech_waveform.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/reader_back_to_tts_pill.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/reader_tts_mini_player_bar.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/tts_bottom_player_controls.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/tts_voice_selection_panel.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/waveform_scrubber.dart';
import 'package:readaway_core/readaway_core.dart' show TtsChunk;

import '../../../../../helpers/test_helpers.dart';

void main() {
  group('Metro TTS Player UI - Zero Circular Geometry & Flat Styling', () {
    testWidgets(
      'ReaderTtsMiniPlayerBar renders flat rectangular styling with zero circular icons',
      (tester) async {
        final tts = MockReaderTtsRepository();
        final readerBloc = MockReaderBloc();
        final ttsBloc = MockReaderTtsBloc(ttsRepository: tts);
        final settingsBloc = MockSettingsBloc();

        when(tts.playbackState).thenAnswer(
          (_) => Stream.value(
            const TtsPlaybackEvent(TtsPlaybackState.paused),
          ),
        );
        when(tts.currentChunk).thenAnswer(
          (_) => Stream.value(
            const TtsChunk(
              id: 'c1',
              sectionIndex: 0,
              sentenceIndex: 0,
              text: 'A beginning is a very delicate time.',
              startOffset: 0,
              endOffset: 37,
            ),
          ),
        );
        when(tts.baseTag).thenReturn(null);

        await tester.pumpTestApp(
          Scaffold(
            body: ReaderTtsMiniPlayerBar(onClosePlayer: () {}),
          ),
          readerBloc: readerBloc,
          readerTtsBloc: ttsBloc,
          readerTtsInitialState: const ReaderTtsState(
            ttsActive: true,
            ttsCurrentPage: 2,
          ),
          settingsBloc: settingsBloc,
        );
        await tester.pumpAndSettle();

        // Lowercase page indicator badge
        expect(find.text('p. 3'), findsOneWidget);
        expect(
          find.text('A beginning is a very delicate time.'),
          findsOneWidget,
        );

        // Play button is a flat rectangular MetroPressable tile
        final playIconFinder = find.byIcon(LucideIcons.play);
        expect(playIconFinder, findsOneWidget);
        final playMetroPressable = find.ancestor(
          of: playIconFinder,
          matching: find.byType(MetroPressable),
        );
        expect(playMetroPressable, findsOneWidget);

        final playContainer = tester.widget<Container>(
          find.descendant(
            of: playMetroPressable,
            matching: find.byType(Container),
          ),
        );
        final playDec = playContainer.decoration as BoxDecoration;
        expect(playDec.shape, isNot(BoxShape.circle));

        // Close button uses LucideIcons.x (not circular)
        final closeIconFinder = find.byIcon(LucideIcons.x);
        expect(closeIconFinder, findsOneWidget);

        // Assert zero CircleAvatar or BoxShape.circle anywhere in mini player bar
        expect(find.byType(CircleAvatar), findsNothing);
        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(ReaderTtsMiniPlayerBar),
            matching: find.byType(Container),
          ),
        );
        for (final container in containers) {
          final decoration = container.decoration;
          if (decoration is BoxDecoration) {
            expect(decoration.shape, isNot(BoxShape.circle));
            if (decoration.borderRadius != null) {
              expect(decoration.borderRadius, BorderRadius.zero);
            }
          }
        }
      },
    );

    testWidgets(
      'TtsBottomPlayerControls renders flat rectangular hero play button and setting pills',
      (tester) async {
        final tts = MockReaderTtsRepository();
        final readerBloc = MockReaderBloc();
        final ttsBloc = MockReaderTtsBloc(ttsRepository: tts);
        final settingsBloc = MockSettingsBloc();

        when(tts.loadAvailableVoices()).thenAnswer((_) async => []);
        when(tts.positionDataStream).thenAnswer((_) => const Stream.empty());
        when(tts.currentWaveform).thenAnswer((_) => const Stream.empty());
        when(tts.playbackState).thenAnswer(
          (_) => Stream.value(
            const TtsPlaybackEvent(
              TtsPlaybackState.error,
              message: 'TTS buffer empty',
            ),
          ),
        );
        when(tts.baseTag).thenReturn(null);
        when(tts.currentVoiceOption).thenAnswer((_) => const Stream.empty());
        when(tts.currentVoice).thenReturn(null);
        when(tts.rateStream).thenAnswer((_) => const Stream.empty());
        when(tts.rate).thenReturn(1.0);
        when(tts.pitchStream).thenAnswer((_) => const Stream.empty());
        when(tts.pitch).thenReturn(1.0);

        await tester.pumpTestApp(
          Scaffold(
            body: TtsBottomPlayerControls(tts: tts),
          ),
          readerBloc: readerBloc,
          readerTtsBloc: ttsBloc,
          readerTtsInitialState: const ReaderTtsState(
            ttsActive: true,
            ttsCurrentPage: 0,
          ),
          settingsBloc: settingsBloc,
        );
        await tester.pumpAndSettle();

        // Error banner renders with non-circular LucideIcons.triangleAlert
        expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
        expect(find.byIcon(LucideIcons.circleAlert), findsNothing);
        expect(find.text('TTS buffer empty'), findsOneWidget);

        // Setting pill icons are present
        expect(find.byIcon(LucideIcons.mic), findsOneWidget);
        expect(find.byIcon(LucideIcons.gauge), findsOneWidget);
        expect(find.byIcon(LucideIcons.audioWaveform), findsOneWidget);
        expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
        expect(find.byIcon(LucideIcons.moon), findsOneWidget);

        // Hero Play/Pause button has flat rectangular geometry
        final playIconFinder = find.byIcon(LucideIcons.play);
        expect(playIconFinder, findsOneWidget);
        final playTileFinder = find.ancestor(
          of: playIconFinder,
          matching: find.byType(MetroPressable),
        );
        expect(playTileFinder, findsOneWidget);

        final playContainer = tester.widget<Container>(
          find.descendant(
            of: playTileFinder,
            matching: find.byType(Container),
          ),
        );
        final playDec = playContainer.decoration as BoxDecoration;
        expect(playDec.shape, isNot(BoxShape.circle));
        if (playDec.borderRadius != null) {
          expect(playDec.borderRadius, BorderRadius.zero);
        }

        // Verify all containers inside controls have zero circular shapes
        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(TtsBottomPlayerControls),
            matching: find.byType(Container),
          ),
        );
        for (final container in containers) {
          final decoration = container.decoration;
          if (decoration is BoxDecoration) {
            expect(decoration.shape, isNot(BoxShape.circle));
            if (decoration.borderRadius != null) {
              expect(decoration.borderRadius, BorderRadius.zero);
            }
          }
        }
      },
    );

    testWidgets(
      'TtsVoiceSelectionPanel uses square check glyphs and flat geometry without circular icons',
      (tester) async {
        final voice1 = fakeTtsVoiceOption(
          id: 'v1',
          label: 'Amy',
          languageCode: 'en_US',
        );
        final voice2 = fakeTtsVoiceOption(
          id: 'v2',
          label: 'David',
          languageCode: 'en_GB',
        );

        await tester.pumpTestApp(
          Scaffold(
            body: TtsVoiceSelectionPanel(
              currentVoice: voice1,
              availableVoices: [voice1, voice2],
              onVoiceSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Flat lowercase headers and labels
        expect(find.text('voice'), findsOneWidget);
        expect(find.text('Amy'), findsOneWidget);
        expect(find.text('David'), findsOneWidget);

        // Square check glyphs instead of circular radio buttons
        expect(find.byIcon(LucideIcons.squareCheck), findsOneWidget);
        expect(find.byIcon(LucideIcons.square), findsOneWidget);

        // Zero circular check or circle icons anywhere
        expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
        expect(find.byIcon(LucideIcons.circle), findsNothing);

        // Containers must use BorderRadius.zero
        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(TtsVoiceSelectionPanel),
            matching: find.byType(Container),
          ),
        );
        for (final container in containers) {
          final decoration = container.decoration;
          if (decoration is BoxDecoration && decoration.borderRadius != null) {
            expect(decoration.borderRadius, BorderRadius.zero);
          }
        }
      },
    );

    testWidgets(
      'ReaderBackToTtsPill renders flat rectangular banner with lowercase Segoe text',
      (tester) async {
        final tts = MockReaderTtsRepository();
        final readerBloc = MockReaderBloc();
        final ttsBloc = MockReaderTtsBloc(ttsRepository: tts);
        final settingsBloc = MockSettingsBloc();

        await tester.pumpTestApp(
          const Stack(
            children: [
              ReaderBackToTtsPill(),
            ],
          ),
          readerBloc: readerBloc,
          readerInitialState: const ReaderState(
            currentPage: 4,
          ),
          readerTtsBloc: ttsBloc,
          readerTtsInitialState: const ReaderTtsState(
            ttsActive: true,
            ttsCurrentPage: 1,
          ),
          settingsBloc: settingsBloc,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Lowercase label with page number
        expect(find.text('listen • page 2'), findsOneWidget);

        // MetroPressable and Container have BorderRadius.zero
        final pillFinder = find.byType(ReaderBackToTtsPill);
        expect(pillFinder, findsOneWidget);
        final pressableFinder = find.descendant(
          of: pillFinder,
          matching: find.byType(MetroPressable),
        );
        expect(pressableFinder, findsOneWidget);

        final containerFinder = find.descendant(
          of: pressableFinder,
          matching: find.byType(Container),
        );
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.zero);
        expect(decoration.shape, isNot(BoxShape.circle));

        // Non-circular vector icons
        expect(find.byIcon(LucideIcons.audioLines), findsOneWidget);
        expect(find.byIcon(LucideIcons.arrowUpRight), findsOneWidget);
      },
    );

    test(
      'WaveformScrubber and LiveSpeechWaveform default to flat rectangular geometry',
      () {
        const scrubber = WaveformScrubber(
          position: Duration(seconds: 1),
          duration: Duration(seconds: 5),
          waveform: [0.1, 0.5, 0.9],
        );
        expect(scrubber.barRadius, 0.0);

        const liveWaveform = LiveSpeechWaveform(
          isPlaying: true,
        );
        expect(liveWaveform.barRadius, 0.0);
      },
    );
  });
}
