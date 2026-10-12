import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/library/presentation/bloc/library_bloc.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/tts/reader_tts_bloc.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'package:readaway/src/features/settings/presentation/bloc/tts_library/tts_library_bloc.dart';

export 'test_bloc_mocks.dart';

extension WidgetTestHarnessExtension on WidgetTester {
  /// Pumps [child] wrapped in a [MaterialApp] and configured [BlocProvider]s.
  ///
  /// Any BLoC passed in will have its initial state wired with `whenListen`,
  /// cutting repetitive setup in widget tests.
  Future<void> pumpTestApp(
    Widget child, {
    ReaderBloc? readerBloc,
    ReaderState readerInitialState = const ReaderState(),
    ReaderTtsBloc? readerTtsBloc,
    ReaderTtsState readerTtsInitialState = const ReaderTtsState(),
    SettingsBloc? settingsBloc,
    SettingsState settingsInitialState = const SettingsState(
      globalReaderPrefs: ReaderPreferences(),
    ),
    AnnotationsBloc? annotationsBloc,
    AnnotationsState annotationsInitialState = const AnnotationsState(),
    LibraryBloc? libraryBloc,
    LibraryState libraryInitialState = const LibraryState(),
    TtsLibraryBloc? ttsLibraryBloc,
    TtsLibraryState ttsLibraryInitialState = const TtsLibraryState(),
    ThemeData? theme,
    NavigatorObserver? navigatorObserver,
    bool wrapScaffold = false,
  }) async {
    final providers = <BlocProvider>[];

    if (readerBloc != null) {
      whenListen(
        readerBloc,
        const Stream<ReaderState>.empty(),
        initialState: readerInitialState,
      );
      providers.add(BlocProvider<ReaderBloc>.value(value: readerBloc));
    }
    if (readerTtsBloc != null) {
      whenListen(
        readerTtsBloc,
        const Stream<ReaderTtsState>.empty(),
        initialState: readerTtsInitialState,
      );
      providers.add(BlocProvider<ReaderTtsBloc>.value(value: readerTtsBloc));
    }
    if (settingsBloc != null) {
      whenListen(
        settingsBloc,
        const Stream<SettingsState>.empty(),
        initialState: settingsInitialState,
      );
      providers.add(BlocProvider<SettingsBloc>.value(value: settingsBloc));
    }
    if (annotationsBloc != null) {
      whenListen(
        annotationsBloc,
        const Stream<AnnotationsState>.empty(),
        initialState: annotationsInitialState,
      );
      providers.add(
        BlocProvider<AnnotationsBloc>.value(value: annotationsBloc),
      );
    }
    if (libraryBloc != null) {
      whenListen(
        libraryBloc,
        const Stream<LibraryState>.empty(),
        initialState: libraryInitialState,
      );
      providers.add(BlocProvider<LibraryBloc>.value(value: libraryBloc));
    }
    if (ttsLibraryBloc != null) {
      whenListen(
        ttsLibraryBloc,
        const Stream<TtsLibraryState>.empty(),
        initialState: ttsLibraryInitialState,
      );
      providers.add(
        BlocProvider<TtsLibraryBloc>.value(value: ttsLibraryBloc),
      );
    }

    Widget content = child;
    if (wrapScaffold) {
      content = Scaffold(body: content);
    }

    if (providers.isNotEmpty) {
      content = MultiBlocProvider(
        providers: providers,
        child: content,
      );
    }

    await pumpWidget(
      MaterialApp(
        theme: theme,
        navigatorObservers: [
          ?navigatorObserver,
        ],
        home: content,
      ),
    );
  }
}
