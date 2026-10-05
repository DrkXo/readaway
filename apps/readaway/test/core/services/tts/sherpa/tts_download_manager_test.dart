import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:readaway/src/core/services/background_downloader_service.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/storage/hive/app_storage_service.dart';
import 'package:readaway/src/core/services/tts/extractor/tts_archive_extractor.dart';
import 'package:readaway/src/core/services/tts/sherpa/tts_download_manager.dart';
import 'package:readaway/src/core/services/tts/tts_download_task.dart';
import 'package:readaway/src/core/services/tts/tts_model_store.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';

class FakeAppPathService extends Fake implements AppPathService {
  FakeAppPathService(this.baseDir);
  final Directory baseDir;

  @override
  Future<Directory> get tempDirectory async => baseDir;

  @override
  Future<Directory> getTtsModelsDirectory() async {
    final dir = Directory('${baseDir.path}/tts_models');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}

class FakeAppStorageService extends Fake implements AppStorageService {
  final Map<dynamic, dynamic> _memoryBox = {};

  @override
  Box<dynamic> get ttsBox => _FakeBox(_memoryBox);
}

class _FakeBox extends Fake implements Box<dynamic> {
  _FakeBox(this._data);
  final Map<dynamic, dynamic> _data;

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();
}

/// Controllable stand-in for [BackGroundDownloaderService]. `download()`
/// returns a real [Transfer] (constructed directly, no native worker) and
/// creates the target file, so the manager's pipeline sees the same shape it
/// would in production. Tests drive completion via [complete]/[fail].
class FakeDownloaderService extends Fake
    implements BackGroundDownloaderService {
  List<Transfer> rehydrated = [];
  final Map<String, Transfer> transfersByTaskId = {};
  int downloadCalls = 0;
  Directory? saveDirOverride;

  @override
  Future<void> ensureInitialized({
    bool autoCleanDatabase = true,
    bool requestNotificationPermission = true,
  }) async {}

  @override
  List<Transfer> all() => [...rehydrated, ...transfersByTaskId.values];

  @override
  Future<Transfer> download({
    String? taskId,
    required String url,
    Map<String, String>? urlQueryParameters,
    required String filename,
    Map<String, String> headers = const {},
    String? httpRequestMethod,
    Directory? saveDirectory,
    String? directory,
    BaseDirectory? baseDirectory,
    String group = 'default',
    bool requiresWiFi = false,
    int retries = 3,
    int? priority,
    String metaData = '',
    String displayName = '',
    TaskOptions? options,
    TaskNotificationConfig? notificationConfig,
    bool userInitiated = false,
    bool largeFile = false,
    bool useSuggestedFilename = false,
    Duration stallTimeout = const Duration(seconds: 30),
    void Function(double progress)? onProgress,
    void Function(TaskStatus status)? onStatus,
    OnTaskFinishedCallback? onTaskFinished,
  }) async {
    downloadCalls++;
    final task = DownloadTask(
      taskId: taskId,
      url: url,
      filename: filename,
      group: group,
    );
    final transfer = Transfer(task);
    transfersByTaskId[taskId ?? ''] = transfer;

    final dir = saveDirectory ?? saveDirOverride;
    if (dir != null) {
      final file = File(p.join(dir.path, filename));
      if (!file.existsSync()) {
        file.writeAsBytesSync(List<int>.generate(256, (i) => i % 251));
      }
    }
    return transfer;
  }

  Transfer? transferFor(String taskId) => transfersByTaskId[taskId];

  void complete(String taskId) {
    final t =
        transfersByTaskId[taskId] ??
        (throw StateError('No transfer registered for $taskId'));
    t.updateStatus(TaskStatusUpdate(t.task, TaskStatus.complete));
  }

  void fail(String taskId, [String message = 'boom']) {
    final t = transfersByTaskId[taskId];
    if (t == null) {
      throw StateError('No transfer registered for $taskId');
    }
    t.updateStatus(
      TaskStatusUpdate(t.task, TaskStatus.failed, TaskException(message)),
    );
  }
}

class FakeExtractor extends TtsArchiveExtractor {
  int extractCount = 0;
  Completer<void>? extractEntered;
  Completer<void>? releaseExtract;

  @override
  Future<void> extractModelArchive({
    required File archiveFile,
    required Directory destDir,
  }) async {
    extractCount++;
    if (extractEntered != null) {
      extractEntered!.complete();
      extractEntered = null;
    }
    if (releaseExtract != null) {
      await releaseExtract!.future;
    }
    await File(p.join(destDir.path, 'tokens.txt')).writeAsString('tokens');
    await File(p.join(destDir.path, 'model.onnx')).writeAsString('onnx');
  }

  @override
  Future<void> extractEspeakArchive({
    required File archiveFile,
    required Directory targetDir,
    required Directory espeakDir,
  }) async {}
}

/// Polls the event loop until [condition] holds, then returns.
///
/// The pipeline crosses real async boundaries (dart:io, timers, stream
/// plumbing), so a fixed number of [pumpEventQueue] turns is a race: on a
/// loaded machine the downloader may not have been called yet, and driving a
/// transfer that does not exist throws instead of failing the assertion the
/// test is about. Waiting on the observable state each step depends on makes
/// these tests deterministic without changing what they assert.
Future<void> waitFor(
  bool Function() condition, {
  required String description,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out after ${timeout.inSeconds}s waiting for $description');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

/// Polls until [read] stops changing for [stablePolls] consecutive polls.
///
/// Used to assert an *absence* (e.g. "no second runner was created"), where
/// there is no event to wait for.
Future<void> waitUntilStable(
  int Function() read, {
  required String description,
  int stablePolls = 5,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  var last = read();
  var stable = 0;
  while (stable < stablePolls) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final now = read();
    stable = now == last ? stable + 1 : 0;
    last = now;
    if (DateTime.now().isAfter(deadline)) {
      fail('"$description" never settled within ${timeout.inSeconds}s');
    }
  }
}

/// Archive transfer id for [model] (same derivation as the manager).
String archiveTaskId(SherpaTtsModelInfo model) => ttsModelTaskId(model.id);

/// Vocoder transfer id for [model] (same derivation as the manager).
String vocoderTaskId(SherpaTtsModelInfo model) =>
    '${archiveTaskId(model)}-vocoder';

const vitsModel = SherpaTtsModelInfo(
  id: 'vits-piper-en_US-amy-low',
  displayName: 'Amy (Low)',
  languageCode: 'en-US',
  languageLabel: 'English',
  type: SherpaTtsModelType.vits,
  downloadUrl: 'https://example.com/vits-piper-en_US-amy-low.tar.bz2',
  approxSizeMb: 15.0,
);

const matchaModel = SherpaTtsModelInfo(
  id: 'matcha-jenny',
  displayName: 'Jenny',
  languageCode: 'en-US',
  languageLabel: 'English',
  type: SherpaTtsModelType.matcha,
  downloadUrl: 'https://example.com/matcha-jenny.tar.bz2',
  approxSizeMb: 22.0,
  vocoderUrl: 'https://example.com/hifigan_v2.onnx',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsDownloadTask', () {
    test('isActive marks only the in-flight phases as running', () {
      expect(TtsDownloadPhase.queued.isActive, isTrue);
      expect(TtsDownloadPhase.downloadingArchive.isActive, isTrue);
      expect(TtsDownloadPhase.downloadingAuxiliary.isActive, isTrue);
      expect(TtsDownloadPhase.verifyingArchive.isActive, isTrue);
      expect(TtsDownloadPhase.extractingArchive.isActive, isTrue);
      expect(TtsDownloadPhase.finalizing.isActive, isTrue);
      expect(TtsDownloadPhase.done.isActive, isFalse);
      expect(TtsDownloadPhase.paused.isActive, isFalse);
      expect(TtsDownloadPhase.interrupted.isActive, isFalse);
      expect(TtsDownloadPhase.failed.isActive, isFalse);
    });
  });

  group('TtsDownloadManager', () {
    late Directory tempDir;
    late FakeAppPathService fakePath;
    late FakeAppStorageService fakeStorage;
    late TtsModelStore store;
    late FakeDownloaderService fakeDownloader;
    late FakeExtractor extractor;
    late TtsDownloadManager manager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tts_download_test_');
      fakePath = FakeAppPathService(tempDir);
      fakeStorage = FakeAppStorageService();
      store = TtsModelStore(storage: fakeStorage);
      await store.saveCatalog([vitsModel, matchaModel]);
      fakeDownloader = FakeDownloaderService();
      extractor = FakeExtractor();
      manager = TtsDownloadManager(
        backgroundDownloader: fakeDownloader,
        pathService: fakePath,
        store: store,
        archiveExtractor: extractor,
      );
      // NOTE: ensureInitialized() is deliberately NOT called here — bootstrap
      // (interrupted-task registration + marker repair) must be triggered by
      // tests that seed the downloader state first.
    });

    tearDown(() async {
      manager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('start is idempotent — no duplicate runner or transfers', () async {
      final first = manager.start(vitsModel);
      final second = manager.start(vitsModel);

      expect(second, first);

      // The second start must not queue a second pipeline. Wait for the one
      // real download to land, then for the count to settle so a duplicate
      // runner would have shown up before asserting.
      await waitFor(
        () => fakeDownloader.downloadCalls >= 1,
        description: 'the archive transfer to be registered',
      );
      await waitUntilStable(
        () => fakeDownloader.downloadCalls,
        description: 'the downloader call count',
      );

      expect(fakeDownloader.downloadCalls, 1);
      expect(fakeDownloader.transferFor(archiveTaskId(vitsModel)), isNotNull);
    });

    test('happy path installs the model and reports done', () async {
      // The snapshot stream is what the UI consumes; assert the terminal state
      // is actually published, not just readable via taskOf.
      final seen = <TtsDownloadTask>[];
      final sub = manager.snapshots.listen((map) {
        final task = map[vitsModel.id];
        if (task != null) seen.add(task);
      });

      final first = manager.start(vitsModel);
      expect(first.phase, TtsDownloadPhase.queued);

      await waitFor(
        () => fakeDownloader.transferFor(archiveTaskId(vitsModel)) != null,
        description: 'the archive transfer to be registered',
      );
      fakeDownloader.complete(archiveTaskId(vitsModel));
      await waitFor(
        () => store.loadInstalledModels().containsKey(vitsModel.id),
        description: 'the install to be persisted',
      );
      await waitFor(
        () => manager.taskOf(vitsModel.id)?.phase == TtsDownloadPhase.done,
        description: 'the snapshot to report done',
      );

      // Installed state persisted by the manager (single writer).
      final installed = store.loadInstalledModels();
      expect(installed.containsKey(vitsModel.id), isTrue);
      expect(installed[vitsModel.id]?.installedSizeBytes, 15 * 1024 * 1024);

      // Snapshot reports done at fraction 1.
      final task = manager.taskOf(vitsModel.id);
      expect(task?.fraction, 1);

      // Archive extracted once and cleaned up.
      expect(extractor.extractCount, 1);
      final modelsRoot = await fakePath.getTtsModelsDirectory();
      final destDir = Directory(p.join(modelsRoot.path, vitsModel.id));
      expect(
        File(p.join(destDir.path, vitsModel.archiveFileName)).existsSync(),
        isFalse,
      );
      // "finished but not finalized" marker is cleared on success.
      expect(
        File('${p.join(destDir.path, vitsModel.archiveFileName)}.done')
            .existsSync(),
        isFalse,
      );

      expect(manager.isDownloading(vitsModel.id), isFalse);
      expect(seen.any((t) => t.phase == TtsDownloadPhase.done), isTrue);
      // Fraction only ever moves forward across the whole pipeline.
      expect(
        seen.map((t) => t.fraction),
        orderedEquals(
          List<double>.from(seen.map((t) => t.fraction))..sort(),
        ),
      );
      await sub.cancel();
    });

    test(
      'matcha model downloads vocoder through a deterministic aux task',
      () async {
        final first = manager.start(matchaModel);
        expect(first.phase, TtsDownloadPhase.queued);

        await waitFor(
          () => fakeDownloader.transferFor(archiveTaskId(matchaModel)) != null,
          description: 'the archive transfer to be registered',
        );
        fakeDownloader.complete(archiveTaskId(matchaModel));

        // Vocoder transfer uses the stable `-vocoder` task id.
        await waitFor(
          () => fakeDownloader.transferFor(vocoderTaskId(matchaModel)) != null,
          description: 'the vocoder transfer to be registered',
        );

        final taskBefore = manager.taskOf(matchaModel.id);
        expect(taskBefore?.phase, TtsDownloadPhase.downloadingAuxiliary);

        fakeDownloader.complete(vocoderTaskId(matchaModel));
        await waitFor(
          () => manager.taskOf(matchaModel.id)?.phase == TtsDownloadPhase.done,
          description: 'the task to report done',
        );

        expect(store.loadInstalledModels().containsKey(matchaModel.id), isTrue);
      },
    );

    test('cancel during extraction never installs the model', () async {
      extractor.extractEntered = Completer<void>();
      extractor.releaseExtract = Completer<void>();

      manager.start(vitsModel);
      await waitFor(
        () => fakeDownloader.transferFor(archiveTaskId(vitsModel)) != null,
        description: 'the archive transfer to be registered',
      );
      fakeDownloader.complete(archiveTaskId(vitsModel));

      // Extraction started; cancel mid-extract.
      await extractor.extractEntered!.future;
      expect(extractor.extractCount, 1);
      await manager.cancel(vitsModel.id);

      // Let extraction finish — the runner must abort BEFORE finalize.
      extractor.releaseExtract!.complete();
      await waitFor(
        () => manager.taskOf(vitsModel.id) == null,
        description: 'the canceled runner to be removed from snapshots',
      );

      expect(store.loadInstalledModels().isEmpty, isTrue);
    });

    test('rehydrated running transfer is normalized to interrupted', () async {
      final rehydrated = Transfer(
        DownloadTask(
          taskId: archiveTaskId(vitsModel),
          url: vitsModel.downloadUrl,
          filename: vitsModel.archiveFileName,
        ),
        null,
        TaskStatus.running,
        0.4,
      );
      fakeDownloader.rehydrated = [rehydrated];

      await manager.ensureInitialized();

      final task = manager.taskOf(vitsModel.id);
      expect(task, isNotNull);
      expect(task?.phase, TtsDownloadPhase.interrupted);
      expect(task?.interrupted, isTrue);
      expect(task?.fraction, closeTo(0.85 * 0.4, 0.001));
      expect(manager.isDownloading(vitsModel.id), isFalse);
    });

    test('interrupted task resumes manually and installs', () async {
      final rehydrated = Transfer(
        DownloadTask(
          taskId: archiveTaskId(vitsModel),
          url: vitsModel.downloadUrl,
          filename: vitsModel.archiveFileName,
        ),
        null,
        TaskStatus.running,
        0.6,
      );
      fakeDownloader.rehydrated = [rehydrated];
      await manager.ensureInitialized();

      final interrupted = manager.taskOf(vitsModel.id);
      expect(interrupted?.phase, TtsDownloadPhase.interrupted);

      await manager.resume(vitsModel.id);

      // Pipeline reattached and the (fake) transfer progressed to completion.
      await waitFor(
        () => fakeDownloader.transferFor(archiveTaskId(vitsModel)) != null,
        description: 'the reattached archive transfer to be registered',
      );
      fakeDownloader.complete(archiveTaskId(vitsModel));
      await waitFor(
        () => store.loadInstalledModels().containsKey(vitsModel.id),
        description: 'the install to be persisted',
      );
      await waitFor(
        () => manager.taskOf(vitsModel.id)?.phase == TtsDownloadPhase.done,
        description: 'the task to report done',
      );
    });

    test('bootstrap repairs archive-landed models via done markers', () async {
      final modelsRoot = await fakePath.getTtsModelsDirectory();
      final destDir = Directory(p.join(modelsRoot.path, vitsModel.id));
      await destDir.create(recursive: true);
      // Simulate: archive transfer finished, but install never finalized.
      final archive = File(p.join(destDir.path, vitsModel.archiveFileName));
      await archive.writeAsBytes(List<int>.generate(256, (i) => i % 251));
      await File('${archive.path}.done').writeAsString(
        jsonEncode({'taskId': archiveTaskId(vitsModel)}),
      );

      await manager.ensureInitialized();
      await waitFor(
        () => manager.taskOf(vitsModel.id)?.phase == TtsDownloadPhase.done,
        description: 'the repaired model to report done',
      );

      expect(store.loadInstalledModels().containsKey(vitsModel.id), isTrue);
      expect(extractor.extractCount, 1);
    });

    test(
      'failed pipeline reports the transfer error to the snapshot',
      () async {
        manager.start(vitsModel);
        await waitFor(
          () => fakeDownloader.transferFor(archiveTaskId(vitsModel)) != null,
          description: 'the archive transfer to be registered',
        );
        fakeDownloader.fail(archiveTaskId(vitsModel), 'disk full');
        await waitFor(
          () => manager.taskOf(vitsModel.id)?.phase == TtsDownloadPhase.failed,
          description: 'the task to report failed',
        );

        // The failure reason is what the voice library renders under the row —
        // prefixed exactly once with the model that failed.
        expect(
          manager.taskOf(vitsModel.id)?.errorMessage,
          'Failed to download ${vitsModel.id}: disk full',
        );
        expect(store.loadInstalledModels().isEmpty, isTrue);
      },
    );
  });
}
