import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_tts_repository.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/reader_tts_mini_player_bar.dart';
import 'package:readaway/src/features/reader/presentation/widgets/tts/reader_tts_player_overlay.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'package:readaway_core/readaway_core.dart' show TtsTimeline;
import 'package:rxdart/rxdart.dart';

import '../../../../../helpers/test_mocks.dart';

class _MockReaderBloc extends MockBloc<ReaderEvent, ReaderState>
    implements ReaderBloc {
  _MockReaderBloc(this.ttsRepository);

  @override
  final ReaderTtsRepository ttsRepository;
}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  testWidgets('drawer remains interactive above the active TTS mini-player', (
    tester,
  ) async {
    final tts = MockReaderTtsRepository();
    final bloc = _MockReaderBloc(tts);
    final settingsBloc = _MockSettingsBloc();
    final timeline = BehaviorSubject<TtsTimeline?>.seeded(null);
    addTearDown(timeline.close);
    when(tts.timelineStream).thenAnswer((_) => timeline);
    whenListen(
      bloc,
      const Stream<ReaderState>.empty(),
      initialState: const ReaderState(ttsActive: true),
    );
    whenListen(
      settingsBloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsState(
        globalReaderPrefs: ReaderPreferences(),
      ),
    );
    var drawerActionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ReaderBloc>.value(
          value: bloc,
          child: BlocProvider<SettingsBloc>.value(
            value: settingsBloc,
            child: Scaffold(
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
          ),
        ),
      ),
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
