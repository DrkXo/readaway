import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/features/reader/presentation/bloc/tts/reader_tts_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/reader_tts_mini_player_bar.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/reader_tts_player_overlay.dart';
import 'package:readaway_core/readaway_core.dart' show TtsTimeline;
import 'package:rxdart/rxdart.dart';

import '../../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('drawer remains interactive above the active TTS mini-player', (
    tester,
  ) async {
    final tts = MockReaderTtsRepository();
    final bloc = MockReaderBloc();
    final ttsBloc = MockReaderTtsBloc(ttsRepository: tts);
    final settingsBloc = MockSettingsBloc();
    final timeline = BehaviorSubject<TtsTimeline?>.seeded(null);
    addTearDown(timeline.close);
    when(tts.timelineStream).thenAnswer((_) => timeline);

    var drawerActionCount = 0;

    await tester.pumpTestApp(
      Scaffold(
        drawer: Drawer(
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 80,
                child: TextButton(
                  onPressed: () => drawerActionCount++,
                  child: const Text('Drawer action'),
                ),
              ),
            ],
          ),
        ),
        body: ReaderTtsPlayerOverlay(
          child: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Text('Open drawer'),
              ),
            ),
          ),
        ),
      ),
      readerBloc: bloc,
      readerTtsBloc: ttsBloc,
      readerTtsInitialState: const ReaderTtsState(ttsActive: true),
      settingsBloc: settingsBloc,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ReaderTtsMiniPlayerBar), findsOneWidget);
    await tester.tap(find.text('Open drawer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Drawer action'), findsOneWidget);
    await tester.tap(find.text('Drawer action'));
    expect(drawerActionCount, 1);
  });
}
