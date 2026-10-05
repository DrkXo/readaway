import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_preferences_repository.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'package:readaway/src/features/settings/presentation/widgets/settings_bloc_x.dart';

class _MemoryReaderPreferencesRepository
    implements ReaderPreferencesRepository {
  ReaderPreferences global = const ReaderPreferences();
  final Map<String, ReaderPreferences> documents = {};
  final List<Completer<Result<ReaderPreferences?>>> documentReads = [];
  int _nextDocumentRead = 0;
  Result<void> saveResult = const Success(null);
  Result<void> resetResult = const Success(null);

  @override
  Future<Result<ReaderPreferences>> getGlobalPreferences() async =>
      Success(global);

  @override
  Future<Result<void>> saveGlobalPreferences(ReaderPreferences prefs) async {
    if (saveResult.isSuccess) global = prefs;
    return saveResult;
  }

  @override
  Future<Result<ReaderPreferences?>> getDocumentPreferences(String path) {
    if (documentReads.isNotEmpty) {
      return documentReads[_nextDocumentRead++].future;
    }
    return Future.value(Success(documents[path]));
  }

  @override
  Future<Result<void>> saveDocumentPreferences(
    String path,
    ReaderPreferences prefs,
  ) async {
    if (saveResult.isSuccess) documents[path] = prefs;
    return saveResult;
  }

  @override
  Future<Result<void>> clearDocumentPreferences(String path) async {
    if (saveResult.isSuccess) documents.remove(path);
    return saveResult;
  }

  @override
  Future<Result<void>> resetAllPreferences() async {
    if (resetResult.isSuccess) {
      global = const ReaderPreferences();
      documents.clear();
    }
    return resetResult;
  }

  @override
  Future<Result<void>> importGlobalPreferences(ReaderPreferences prefs) async {
    global = prefs;
    return const Success(null);
  }
}

class _MemorySettingsRepository implements SettingsRepository {
  Settings current = const Settings();
  Result<void> saveResult = const Success(null);
  Result<void> resetResult = const Success(null);

  @override
  Future<Result<Settings>> getSettings() async => Success(current);

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    if (saveResult.isSuccess) current = settings;
    return saveResult;
  }

  @override
  Future<Result<void>> resetSettings() async {
    if (resetResult.isSuccess) current = const Settings();
    return resetResult;
  }

  @override
  Stream<Settings> watchSettings() => const Stream.empty();
}

void main() {
  late _MemoryReaderPreferencesRepository preferences;
  late _MemorySettingsRepository settings;
  late SettingsBloc bloc;

  setUp(() {
    preferences = _MemoryReaderPreferencesRepository();
    settings = _MemorySettingsRepository();
  });

  SettingsBloc buildBloc() {
    bloc = SettingsBloc(
      preferencesRepository: preferences,
      settingsRepository: settings,
    );
    return bloc;
  }

  tearDown(() async => bloc.close());

  group('global reader preferences', () {
    blocTest<SettingsBloc, SettingsState>(
      'loads persisted global reader preferences and app settings',
      build: () {
        preferences.global = const ReaderPreferences(fontSize: 21);
        settings.current = const Settings(screenWakeLock: true);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsEvent.loadPrefs()),
      expect: () => [
        isA<SettingsState>()
            .having(
              (state) => state.globalReaderPrefs.fontSize,
              'font size',
              21,
            )
            .having(
              (state) => state.appSettings.screenWakeLock,
              'wake lock',
              true,
            ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'persists edits before exposing the updated global preferences',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.updateReaderPrefs((prefs) => prefs.copyWith(fontSize: 23)),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.globalReaderPrefs.fontSize,
          'font size',
          23,
        ),
      ],
      verify: (_) => expect(preferences.global.fontSize, 23),
    );

    blocTest<SettingsBloc, SettingsState>(
      'does not claim a failed global write succeeded',
      build: () {
        preferences.saveResult = const Failed(StorageWriteFailure('global'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const SettingsEvent.setGlobalReaderPref(
          ReaderPreferences(fontSize: 23),
        ),
      ),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.failure,
          'failure',
          isNotNull,
        ),
      ],
      verify: (_) => expect(bloc.state.globalReaderPrefs.fontSize, 16),
    );
  });

  group('per-book reader preferences', () {
    blocTest<SettingsBloc, SettingsState>(
      'loads multiple books independently and resolves global fallback',
      build: () {
        preferences.global = const ReaderPreferences(fontSize: 18);
        preferences.documents['book-a'] = const ReaderPreferences(fontSize: 27);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const SettingsEvent.loadDocumentPrefs('book-a'));
        bloc.add(const SettingsEvent.loadDocumentPrefs('book-b'));
      },
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.effectiveReaderPrefs('book-a').fontSize,
          'book A font size',
          27,
        ),
        isA<SettingsState>()
            .having(
              (state) => state.effectiveReaderPrefs('book-a').fontSize,
              'book A font size',
              27,
            )
            .having(
              (state) => state.effectiveReaderPrefs('book-b').fontSize,
              'book B fallback font size',
              18,
            ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'the latest requested load for one book wins when requests overlap',
      build: () {
        final firstRead = Completer<Result<ReaderPreferences?>>();
        final secondRead = Completer<Result<ReaderPreferences?>>();
        preferences.documentReads
          ..add(firstRead)
          ..add(secondRead);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const SettingsEvent.loadDocumentPrefs('book-a'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SettingsEvent.loadDocumentPrefs('book-a'));
        await Future<void>.delayed(Duration.zero);
        preferences.documentReads[0].complete(
          const Success(ReaderPreferences(fontSize: 25)),
        );
        preferences.documentReads[1].complete(
          const Success(ReaderPreferences(fontSize: 31)),
        );
      },
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.effectiveReaderPrefs('book-a').fontSize,
          'latest book font size',
          31,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'creates a book override from global values without changing global values',
      build: () {
        preferences.global = const ReaderPreferences(fontSize: 19);
        return buildBloc();
      },
      act: (bloc) => bloc.updateDocumentReaderPrefs(
        'book-a',
        (prefs) => prefs.copyWith(fontSize: 29),
      ),
      skip: 1,
      expect: () => [
        isA<SettingsState>()
            .having(
              (state) => state.effectiveReaderPrefs('book-a').fontSize,
              'book override font size',
              29,
            )
            .having(
              (state) => state.effectiveReaderPrefs('book-b').fontSize,
              'other book global font size',
              19,
            ),
      ],
      verify: (_) => expect(preferences.global.fontSize, 19),
    );

    blocTest<SettingsBloc, SettingsState>(
      'clears an override and returns the book to global preferences',
      build: () {
        preferences.global = const ReaderPreferences(fontSize: 19);
        preferences.documents['book-a'] = const ReaderPreferences(fontSize: 29);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const SettingsEvent.loadDocumentPrefs('book-a'));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.clearDocumentReaderPrefs('book-a');
      },
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.effectiveReaderPrefs('book-a').fontSize,
          'loaded override font size',
          29,
        ),
        isA<SettingsState>().having(
          (state) => state.effectiveReaderPrefs('book-a').fontSize,
          'global fallback font size',
          19,
        ),
      ],
      verify: (_) => expect(preferences.documents.containsKey('book-a'), false),
    );

    blocTest<SettingsBloc, SettingsState>(
      'does not claim a failed book write succeeded',
      build: () {
        preferences.saveResult = const Failed(StorageWriteFailure('book-a'));
        return buildBloc();
      },
      act: (bloc) => bloc.updateDocumentReaderPrefs(
        'book-a',
        (prefs) => prefs.copyWith(fontSize: 29),
      ),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.failure,
          'failure',
          isNotNull,
        ),
      ],
      verify: (_) => expect(bloc.state.documentReaderPrefs, isEmpty),
    );
  });

  group('application settings', () {
    blocTest<SettingsBloc, SettingsState>(
      'persists updates and resets reader and application settings',
      build: () {
        preferences.global = const ReaderPreferences(fontSize: 22);
        preferences.documents['book-a'] = const ReaderPreferences(fontSize: 30);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(
          const SettingsEvent.updateAppSettings(Settings(screenWakeLock: true)),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SettingsEvent.loadDocumentPrefs('book-a'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SettingsEvent.resetAllReaderPrefs());
      },
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.appSettings.screenWakeLock,
          'wake lock',
          true,
        ),
        isA<SettingsState>().having(
          (state) => state.documentReaderPrefs.containsKey('book-a'),
          'loaded book override',
          true,
        ),
        isA<SettingsState>()
            .having(
              (state) => state.appSettings,
              'default app settings',
              const Settings(),
            )
            .having(
              (state) => state.globalReaderPrefs,
              'default reader preferences',
              const ReaderPreferences(),
            )
            .having(
              (state) => state.documentReaderPrefs,
              'cleared book settings',
              isEmpty,
            ),
      ],
      verify: (_) {
        expect(settings.current, const Settings());
        expect(preferences.global, const ReaderPreferences());
        expect(preferences.documents, isEmpty);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'preserves in-memory values if the settings repository rejects an update',
      build: () {
        settings.saveResult = const Failed(StorageWriteFailure('app_settings'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const SettingsEvent.updateAppSettings(Settings(screenWakeLock: true)),
      ),
      skip: 1,
      expect: () => [
        isA<SettingsState>()
            .having(
              (state) => state.appSettings.screenWakeLock,
              'wake lock',
              false,
            )
            .having((state) => state.failure, 'failure', isNotNull),
      ],
      verify: (_) => expect(settings.current.screenWakeLock, false),
    );
  });
}
