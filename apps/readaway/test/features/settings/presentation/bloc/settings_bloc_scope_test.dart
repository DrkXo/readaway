import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<Result<ReaderPreferences>> getGlobalPreferences() async =>
      Success(global);

  @override
  Future<Result<void>> saveGlobalPreferences(ReaderPreferences prefs) async {
    global = prefs;
    return const Success(null);
  }

  @override
  Future<Result<ReaderPreferences?>> getDocumentPreferences(
    String path,
  ) async => Success(documents[path]);

  @override
  Future<Result<void>> saveDocumentPreferences(
    String path,
    ReaderPreferences prefs,
  ) async {
    documents[path] = prefs;
    return const Success(null);
  }

  @override
  Future<Result<void>> clearDocumentPreferences(String path) async {
    documents.remove(path);
    return const Success(null);
  }

  @override
  Future<Result<void>> resetAllPreferences() async {
    global = const ReaderPreferences();
    documents.clear();
    return const Success(null);
  }

  @override
  Future<Result<void>> importGlobalPreferences(ReaderPreferences prefs) async {
    global = prefs;
    return const Success(null);
  }
}

class _MemorySettingsRepository implements SettingsRepository {
  Settings current = const Settings();

  @override
  Future<Result<Settings>> getSettings() async => Success(current);

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    current = settings;
    return const Success(null);
  }

  @override
  Future<Result<void>> resetSettings() async {
    current = const Settings();
    return const Success(null);
  }

  @override
  Stream<Settings> watchSettings() => const Stream.empty();
}

/// Lets the bloc's async handlers and queued events finish.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  const book = '/library/book.epub';

  late _MemoryReaderPreferencesRepository prefs;
  late _MemorySettingsRepository settings;
  late SettingsBloc bloc;

  setUp(() {
    prefs = _MemoryReaderPreferencesRepository();
    settings = _MemorySettingsRepository();
    bloc = SettingsBloc(
      preferencesRepository: prefs,
      settingsRepository: settings,
    );
  });

  tearDown(() => bloc.close());

  test('does not create a per-book override when the book has none', () async {
    await _settle();
    expect(bloc.state.documentReaderPrefs, isEmpty);

    bloc.updateReaderPrefsWithinScope(
      (p) => p.copyWith(fontSize: 22),
      documentPath: book,
    );
    await _settle();

    expect(bloc.state.documentReaderPrefs.containsKey(book), isFalse);
    expect(bloc.state.globalReaderPrefs.fontSize, 22);
    expect(prefs.global.fontSize, 22);
    expect(prefs.documents, isEmpty);
  });

  test('updates the per-book override when the book already has one', () async {
    prefs.documents[book] = const ReaderPreferences(fontSize: 18);
    await _settle();
    bloc.add(const SettingsEvent.loadDocumentPrefs(book));
    await _settle();
    expect(bloc.state.documentReaderPrefs.containsKey(book), isTrue);

    bloc.updateReaderPrefsWithinScope(
      (p) => p.copyWith(brightnessOverlay: 0.4),
      documentPath: book,
    );
    await _settle();

    expect(bloc.state.documentReaderPrefs[book]?.brightnessOverlay, 0.4);
    expect(bloc.state.globalReaderPrefs.brightnessOverlay, 0);
    expect(prefs.global.brightnessOverlay, 0);
  });
}
