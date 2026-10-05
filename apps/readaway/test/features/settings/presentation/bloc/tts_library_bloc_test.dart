import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/services/tts/cache/tts_chapter_cache_service.dart';
import 'package:readaway/src/core/services/tts/catalog/tts_catalog_service.dart';
import 'package:readaway/src/core/services/tts/importer/custom_tts_model_importer_service.dart';
import 'package:readaway/src/core/services/tts/sherpa/tts_download_manager.dart';
import 'package:readaway/src/core/services/tts/tts_download_task.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:readaway/src/features/settings/domain/repositories/tts_model_repository.dart';
import 'package:readaway/src/features/settings/presentation/bloc/tts_library/tts_library_bloc.dart';
import 'package:rxdart/rxdart.dart';

const _vitsModel = SherpaTtsModelInfo(
  id: 'vits-piper-en_US-amy-low',
  displayName: 'Amy (Low)',
  languageCode: 'en-US',
  languageLabel: 'English',
  type: SherpaTtsModelType.vits,
  downloadUrl: 'https://example.com/vits-piper-en_US-amy-low.tar.bz2',
  approxSizeMb: 15.0,
);

const _matchaModel = SherpaTtsModelInfo(
  id: 'matcha-jenny',
  displayName: 'Jenny',
  languageCode: 'en-US',
  languageLabel: 'English',
  type: SherpaTtsModelType.matcha,
  downloadUrl: 'https://example.com/matcha-jenny.tar.bz2',
  approxSizeMb: 22.0,
);

const _customModel = SherpaTtsModelInfo(
  id: 'custom-my-voice',
  displayName: 'My Voice',
  languageCode: 'en',
  languageLabel: 'English',
  type: SherpaTtsModelType.vits,
  downloadUrl: '',
  approxSizeMb: 5.0,
  isCustom: true,
);

class _FakeTtsModelRepository implements TtsModelRepository {
  _FakeTtsModelRepository({
    required List<SherpaTtsModelInfo> catalog,
    required List<SherpaTtsModelInfo> installed,
  }) : catalogController = BehaviorSubject.seeded(List.of(catalog)),
       installedController = BehaviorSubject.seeded(List.of(installed));

  final BehaviorSubject<List<SherpaTtsModelInfo>> catalogController;
  final BehaviorSubject<List<SherpaTtsModelInfo>> installedController;

  @override
  String? activeModelId;

  final activateCalls = <String>[];
  final deleteCalls = <String>[];
  final previewCalls = <String>[];
  int stopPreviewCount = 0;

  Result<void> activateResult = const Success(null);
  Result<void> deleteResult = const Success(null);
  Result<TtsCatalogSyncResult> syncResult = const Success(
    TtsCatalogSyncResult(
      totalModels: 0,
      newModelsCount: 0,
      updatedModelsCount: 0,
    ),
  );
  Result<SherpaTtsModelInfo> importResult = const Failed(
    TtsSynthesisFailure('boom'),
  );
  Completer<Result<void>>? playGate;

  @override
  Future<Result<List<SherpaTtsModelInfo>>> getCatalog({
    bool forceRefresh = false,
  }) async {
    return Success(catalogController.value);
  }

  @override
  Stream<List<SherpaTtsModelInfo>> watchCatalog() => catalogController.stream;

  @override
  Stream<List<SherpaTtsModelInfo>> watchInstalledModels() =>
      installedController.stream;

  @override
  List<SherpaTtsModelInfo> get availableModels => catalogController.value;

  @override
  Future<Result<List<SherpaTtsModelInfo>>> getInstalledModels() async =>
      Success(installedController.value);

  @override
  Future<Result<void>> activateModel(String modelId) async {
    activateCalls.add(modelId);
    activeModelId = modelId;
    return activateResult;
  }

  @override
  Future<Result<void>> deleteModel(String modelId) async {
    deleteCalls.add(modelId);
    // Mirror the real store-backed repo: deleting a model removes it from the
    // installed list, which re-emits through watchInstalledModels().
    installedController.add(
      installedController.value.where((m) => m.id != modelId).toList(),
    );
    return deleteResult;
  }

  @override
  Future<Result<TtsCatalogSyncResult>> checkForCatalogUpdates() async =>
      syncResult;

  @override
  Future<Result<CustomModelInspectionResult>> inspectCustomModel(
    String sourcePath,
  ) => throw UnimplementedError();

  @override
  Future<Result<SherpaTtsModelInfo>> importCustomModel({
    required CustomModelInspectionResult inspection,
    required String displayName,
    required String languageCode,
    required String languageLabel,
    SherpaTtsModelType? typeOverride,
    int speakerCount = 0,
    int sampleRate = 22050,
  }) async {
    return importResult;
  }

  @override
  Future<Result<void>> playPreview(String modelId) async {
    previewCalls.add(modelId);
    if (playGate != null) return playGate!.future;
    return const Success(null);
  }

  @override
  Future<Result<void>> stopPreview() async {
    stopPreviewCount++;
    return const Success(null);
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(Settings initial)
    : settingsController = BehaviorSubject.seeded(initial);

  final BehaviorSubject<Settings> settingsController;
  final savedSettings = <Settings>[];

  @override
  Future<Result<Settings>> getSettings() async =>
      Success(settingsController.value);

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    savedSettings.add(settings);
    settingsController.add(settings);
    return const Success(null);
  }

  @override
  Future<Result<void>> resetSettings() async => const Success(null);

  @override
  Stream<Settings> watchSettings() => settingsController.stream;
}

/// Stand-in for [TtsDownloadManager]: snapshots is a replaying subject so the
/// bloc's subscription wiring is exercised, and action calls are recorded.
class _FakeDownloadManager extends Fake implements TtsDownloadManager {
  final snapshotsController =
      BehaviorSubject<Map<String, TtsDownloadTask>>.seeded(const {});

  final started = <String>[];
  final paused = <String>[];
  final resumed = <String>[];
  final cancelled = <String>[];

  @override
  ValueStream<Map<String, TtsDownloadTask>> get snapshots =>
      snapshotsController;

  @override
  TtsDownloadTask? taskOf(String modelId) => snapshotsController.value[modelId];

  @override
  bool isDownloading(String modelId) =>
      snapshotsController.value[modelId]?.phase.isActive ?? false;

  @override
  TtsDownloadTask start(SherpaTtsModelInfo model) {
    started.add(model.id);
    return snapshotsController.value[model.id] ??
        TtsDownloadTask(modelId: model.id, phase: TtsDownloadPhase.queued);
  }

  @override
  Future<void> pause(String modelId) async => paused.add(modelId);

  @override
  Future<void> resume(String modelId) async => resumed.add(modelId);

  @override
  Future<void> cancel(String modelId) async => cancelled.add(modelId);
}

class _FakeTtsChapterCacheService extends Fake
    implements TtsChapterCacheService {
  int totalBytes = 1024 * 1024 * 15; // 15 MB
  int bookBytes = 1024 * 1024 * 5; // 5 MB
  bool clearedAll = false;
  final clearedBooks = <String>[];

  @override
  Future<int> calculateTotalCacheSizeBytes() async => totalBytes;

  @override
  Future<int> calculateBookCacheSizeBytes(String bookPath) async => bookBytes;

  @override
  Future<void> clearAllCache() async {
    clearedAll = true;
    totalBytes = 0;
    bookBytes = 0;
  }

  @override
  Future<void> clearBookCache(String bookPath) async {
    clearedBooks.add(bookPath);
    totalBytes -= bookBytes;
    bookBytes = 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTtsModelRepository repo;
  late _FakeSettingsRepository settings;
  late _FakeDownloadManager manager;
  late _FakeTtsChapterCacheService cacheService;
  late TtsLibraryBloc bloc;

  Directory? inspectionDir;

  setUp(() {
    repo = _FakeTtsModelRepository(
      catalog: [_vitsModel, _matchaModel],
      installed: [_vitsModel],
    );
    settings = _FakeSettingsRepository(const Settings());
    manager = _FakeDownloadManager();
    cacheService = _FakeTtsChapterCacheService();
    bloc = TtsLibraryBloc(
      ttsModelRepository: repo,
      settingsRepository: settings,
      downloadManager: manager,
      ttsCacheService: cacheService,
    );
  });

  tearDown(() => bloc.close());

  tearDownAll(() {
    inspectionDir?.deleteSync(recursive: true);
  });

  group('TtsLibraryBloc', () {
    test(
      'boot refresh populates catalog, installed, and derived flags',
      () async {
        await pumpEventQueue();

        expect(bloc.state.availableModels, hasLength(2));
        expect(
          bloc.state.installedModels.map((m) => m.id),
          contains(_vitsModel.id),
        );
        expect(bloc.state.isDownloaded(_vitsModel.id), isTrue);
        expect(bloc.state.isDownloaded(_matchaModel.id), isFalse);
        expect(bloc.state.taskOf(_vitsModel.id), isNull);
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'catalog and installed streams push live updates into state',
      () async {
        await pumpEventQueue();

        repo.catalogController.add([_vitsModel, _matchaModel, _customModel]);
        await pumpEventQueue();
        expect(bloc.state.availableModels, hasLength(3));

        repo.installedController.add([_vitsModel, _matchaModel]);
        await pumpEventQueue();
        expect(bloc.state.installedModels, hasLength(2));
        expect(bloc.state.isDownloaded(_matchaModel.id), isTrue);
      },
    );

    test('installed stream clears a vanished active voice', () async {
      await pumpEventQueue();
      bloc.add(TtsLibraryEvent.activate(_matchaModel.id));
      await pumpEventQueue();
      expect(bloc.state.activeModelId, _matchaModel.id);

      repo.installedController.add([_vitsModel]);
      await pumpEventQueue();
      expect(bloc.state.activeModelId, isNull);
    });

    test(
      'persisted active voice is restored on boot when nothing is active',
      () async {
        final seeded = const Settings().copyWith(
          globalViewSettings: const GlobalViewSettings().copyWith(
            ttsVoice: _vitsModel.id,
          ),
        );
        settings.settingsController.add(seeded);

        await pumpEventQueue();

        expect(repo.activateCalls, contains(_vitsModel.id));
        expect(bloc.state.activeModelId, _vitsModel.id);
      },
    );

    test('activate persists the voice and clears busy on success', () async {
      bloc.add(TtsLibraryEvent.activate(_matchaModel.id));
      await pumpEventQueue();

      expect(repo.activateCalls, contains(_matchaModel.id));
      expect(bloc.state.activeModelId, _matchaModel.id);
      expect(bloc.state.busyModelId, isNull);
      expect(bloc.state.error, isNull);
      expect(
        settings.savedSettings.last.globalViewSettings.ttsVoice,
        _matchaModel.id,
      );
    });

    test(
      'activate failure surfaces an error and keeps the previous voice',
      () async {
        repo.activateResult = const Failed(
          TtsSynthesisFailure('activate boom'),
        );

        bloc.add(TtsLibraryEvent.activate(_matchaModel.id));
        await pumpEventQueue();

        expect(bloc.state.error, 'activate boom');
        expect(bloc.state.activeModelId, isNull);
        expect(bloc.state.busyModelId, isNull);
      },
    );

    test(
      'delete removes the model, clears the active voice, and nulls ttsVoice',
      () async {
        bloc.add(TtsLibraryEvent.activate(_vitsModel.id));
        await pumpEventQueue();
        settings.savedSettings.clear();

        bloc.add(TtsLibraryEvent.deleteModel(_vitsModel));
        await pumpEventQueue();

        expect(repo.deleteCalls, contains(_vitsModel.id));
        expect(
          bloc.state.installedModels.map((m) => m.id),
          isNot(contains(_vitsModel.id)),
        );
        expect(bloc.state.activeModelId, isNull);
        expect(
          settings.savedSettings.last.globalViewSettings.ttsVoice,
          isNull,
        );
      },
    );

    test('manager snapshots drive the downloads map', () async {
      final interrupted = TtsDownloadTask(
        modelId: _matchaModel.id,
        phase: TtsDownloadPhase.interrupted,
        fraction: 0.4,
        interrupted: true,
      );
      manager.snapshotsController.add({_matchaModel.id: interrupted});
      await pumpEventQueue();

      final task = bloc.state.taskOf(_matchaModel.id);
      expect(task, isNotNull);
      expect(task?.phase, TtsDownloadPhase.interrupted);
      expect(bloc.state.isDownloading(_matchaModel.id), isFalse);
    });

    test(
      'resumeInterrupted resumes parked tasks, skipping paused ones',
      () async {
        final interrupted = TtsDownloadTask(
          modelId: _matchaModel.id,
          phase: TtsDownloadPhase.interrupted,
          interrupted: true,
        );
        final paused = TtsDownloadTask(
          modelId: _vitsModel.id,
          phase: TtsDownloadPhase.paused,
          fraction: 0.5,
        );
        manager.snapshotsController.add({
          _matchaModel.id: interrupted,
          _vitsModel.id: paused,
        });
        await pumpEventQueue();

        bloc.add(const TtsLibraryEvent.resumeInterrupted());
        await pumpEventQueue();

        expect(manager.resumed, contains(_matchaModel.id));
        expect(manager.resumed, isNot(contains(_vitsModel.id)));
      },
    );

    test('download actions delegate to the manager', () async {
      bloc.add(TtsLibraryEvent.startDownload(_matchaModel));
      await pumpEventQueue();
      expect(manager.started, contains(_matchaModel.id));

      bloc.add(TtsLibraryEvent.pauseDownload(_matchaModel.id));
      await pumpEventQueue();
      expect(manager.paused, contains(_matchaModel.id));

      bloc.add(TtsLibraryEvent.resumeDownload(_matchaModel.id));
      await pumpEventQueue();
      expect(manager.resumed, contains(_matchaModel.id));

      bloc.add(TtsLibraryEvent.cancelDownload(_matchaModel.id));
      await pumpEventQueue();
      expect(manager.cancelled, contains(_matchaModel.id));
    });

    test(
      'startDownload on a model already downloading is a no-op replay',
      () async {
        final task = TtsDownloadTask(
          modelId: _matchaModel.id,
          phase: TtsDownloadPhase.downloadingArchive,
          fraction: 0.3,
        );
        manager.snapshotsController.add({_matchaModel.id: task});
        await pumpEventQueue();

        bloc.add(TtsLibraryEvent.startDownload(_matchaModel));
        await pumpEventQueue();

        // Idempotent: the manager snapshot is untouched (a fresh task is only
        // created for a model with no in-flight pipeline).
        expect(manager.started, contains(_matchaModel.id));
        expect(
          bloc.state.taskOf(_matchaModel.id)?.phase,
          TtsDownloadPhase.downloadingArchive,
        );
      },
    );

    test(
      'checkForUpdates surfaces the notification and replaces the catalog',
      () async {
        repo.syncResult = const Success(
          TtsCatalogSyncResult(
            totalModels: 2,
            newModelsCount: 1,
            updatedModelsCount: 1,
          ),
        );

        bloc.add(const TtsLibraryEvent.checkForUpdates());
        await pumpEventQueue();

        expect(bloc.state.isCheckingUpdates, isFalse);
        expect(bloc.state.updateNotification, contains('1 new voice(s)'));
        expect(bloc.state.updateNotification, contains('1 updated'));
        expect(bloc.state.availableModels, repo.availableModels);
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'importCustomModel adds the voice to installed and notifies',
      () async {
        repo.importResult = const Success(_customModel);
        inspectionDir ??= Directory.systemTemp.createTempSync('tts_inspection');

        bloc.add(
          TtsLibraryEvent.importCustomModel(
            inspection: CustomModelInspectionResult(
              directory: inspectionDir!,
              detectedType: SherpaTtsModelType.vits,
              suggestedDisplayName: 'My Voice',
              suggestedLanguageCode: 'en',
              suggestedLanguageLabel: 'English',
              onnxFiles: const ['model.onnx'],
              hasTokens: true,
              hasVoicesBin: false,
              approxSizeMb: 5.0,
              isArchiveSource: false,
            ),
            displayName: 'My Voice',
            languageCode: 'en',
            languageLabel: 'English',
          ),
        );
        await pumpEventQueue();

        expect(
          bloc.state.installedModels.map((m) => m.id),
          contains(_customModel.id),
        );
        expect(bloc.state.updateNotification, contains('My Voice'));
        expect(bloc.state.error, isNull);
      },
    );

    test('preview marks the model busy during playback, then clears', () async {
      repo.playGate = Completer<Result<void>>();

      bloc.add(TtsLibraryEvent.preview(_matchaModel.id));
      await pumpEventQueue();

      expect(repo.previewCalls, contains(_matchaModel.id));
      expect(bloc.state.busyModelId, _matchaModel.id);

      repo.playGate!.complete(const Success(null));
      await pumpEventQueue();

      expect(bloc.state.busyModelId, isNull);
    });

    test('tapping the busy voice stops the sample mid-playback', () async {
      repo.playGate = Completer<Result<void>>();

      bloc.add(TtsLibraryEvent.preview(_matchaModel.id));
      await pumpEventQueue();
      expect(bloc.state.busyModelId, _matchaModel.id);

      // `playPreview` awaits the whole sample, so the stop tap lands while the
      // first handler is still in flight. It must be handled, not dropped.
      bloc.add(TtsLibraryEvent.preview(_matchaModel.id));
      await pumpEventQueue();

      expect(repo.stopPreviewCount, 1);
      expect(bloc.state.busyModelId, isNull);

      // The superseded playback finishing must not disturb the current state.
      repo.playGate!.complete(const Success(null));
      await pumpEventQueue();

      expect(bloc.state.busyModelId, isNull);
      expect(bloc.state.error, isNull);
    });

    test('previewing a second voice stops the first one', () async {
      repo.playGate = Completer<Result<void>>();

      bloc.add(TtsLibraryEvent.preview(_matchaModel.id));
      await pumpEventQueue();
      expect(bloc.state.busyModelId, _matchaModel.id);

      bloc.add(TtsLibraryEvent.preview(_vitsModel.id));
      await pumpEventQueue();

      expect(repo.stopPreviewCount, 1);
      expect(repo.previewCalls, [_matchaModel.id, _vitsModel.id]);
      expect(bloc.state.busyModelId, _vitsModel.id);
    });

    test('loadCacheSize calculates total and book cache sizes', () async {
      bloc.add(
        const TtsLibraryEvent.loadCacheSize(bookPath: '/books/my_book.epub'),
      );
      await pumpEventQueue();

      expect(bloc.state.totalCacheSizeBytes, equals(1024 * 1024 * 15));
      expect(bloc.state.bookCacheSizeBytes, equals(1024 * 1024 * 5));
      expect(bloc.state.isLoadingCacheSize, isFalse);
    });

    test(
      'clearAllCache deletes all cached audio and emits notification',
      () async {
        bloc.add(const TtsLibraryEvent.loadCacheSize());
        await pumpEventQueue();
        expect(bloc.state.totalCacheSizeBytes, equals(1024 * 1024 * 15));

        bloc.add(const TtsLibraryEvent.clearAllCache());
        await pumpEventQueue();

        expect(cacheService.clearedAll, isTrue);
        expect(bloc.state.totalCacheSizeBytes, equals(0));
        expect(bloc.state.bookCacheSizeBytes, equals(0));
        expect(
          bloc.state.updateNotification,
          equals('All TTS audio cache cleared'),
        );
      },
    );

    test('clearBookCache deletes book audio and updates cache size', () async {
      const bookPath = '/books/my_book.epub';
      bloc.add(const TtsLibraryEvent.loadCacheSize(bookPath: bookPath));
      await pumpEventQueue();

      bloc.add(const TtsLibraryEvent.clearBookCache(bookPath));
      await pumpEventQueue();

      expect(cacheService.clearedBooks, contains(bookPath));
      expect(bloc.state.bookCacheSizeBytes, equals(0));
      expect(bloc.state.totalCacheSizeBytes, equals(1024 * 1024 * 10));
      expect(bloc.state.updateNotification, equals('Cleared book audio cache'));
    });
  });
}
