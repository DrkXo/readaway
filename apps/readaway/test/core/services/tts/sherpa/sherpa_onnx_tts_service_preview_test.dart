import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:readaway/src/core/services/background_downloader_service.dart';
import 'package:readaway/src/core/services/isolate_service.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/storage/hive/app_storage_service.dart';
import 'package:readaway/src/core/services/tts/extractor/tts_archive_extractor.dart';
import 'package:readaway/src/core/services/tts/sherpa/sherpa_onnx_tts_service.dart';
import 'package:readaway/src/core/services/tts/sherpa/tts_download_manager.dart';
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

class FakeDownloaderService extends Fake
    implements BackGroundDownloaderService {
  @override
  Future<void> ensureInitialized({
    bool autoCleanDatabase = true,
    bool requestNotificationPermission = true,
  }) async {}

  @override
  List<Transfer> all() => const [];

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
    throw UnimplementedError('not used by the preview isolation test');
  }
}

class FakeExtractor extends TtsArchiveExtractor {
  @override
  Future<void> extractModelArchive({
    required File archiveFile,
    required Directory destDir,
  }) async {}

  @override
  Future<void> extractEspeakArchive({
    required File archiveFile,
    required Directory targetDir,
    required Directory espeakDir,
  }) async {}
}

/// Records worker-isolate commands and replies with canned responses, so the
/// service's message contract can be asserted without running native code
/// (the isolate is never actually spawned).
class FakeIsolateService extends IsolateService {
  final List<Map<String, dynamic>> commands = [];
  final Map<String, Object> responses = {};

  bool get spawned => true;

  @override
  bool isSpawned(String name) => spawned;

  @override
  Future<SendPort> spawn({
    required String name,
    required void Function(SendPort) entryPoint,
  }) async {
    throw StateError('isolate should never be spawned in this test');
  }

  @override
  Future<T> sendCommand<T>(String name, Map<String, dynamic> command) async {
    commands.add(command);
    final canned = responses[command['type']];
    if (canned is Map && command['type'] == 'generateToFile') {
      return {...canned, 'outputPath': command['outputPath']} as T;
    }
    return canned as T;
  }
}

const previewModel = SherpaTtsModelInfo(
  id: 'vits-piper-en_US-amy-low',
  displayName: 'Amy (Low)',
  languageCode: 'en-US',
  languageLabel: 'English',
  type: SherpaTtsModelType.vits,
  downloadUrl: 'https://example.com/vits-piper-en_US-amy-low.tar.bz2',
  approxSizeMb: 15.0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SherpaOnnxTtsService preview isolation', () {
    late Directory tempDir;
    late FakeAppPathService fakePath;
    late FakeAppStorageService fakeStorage;
    late TtsModelStore store;
    late FakeIsolateService fakeIsolate;
    late SherpaOnnxTtsService service;
    late TtsDownloadManager manager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tts_preview_test_');
      fakePath = FakeAppPathService(tempDir);
      fakeStorage = FakeAppStorageService();
      store = TtsModelStore(storage: fakeStorage);
      await store.saveCatalog([previewModel]);
      await store.saveInstalledModel(previewModel);

      // Materialize the model directory so `indexFiles` resolves.
      final modelsRoot = await fakePath.getTtsModelsDirectory();
      final dir = Directory(p.join(modelsRoot.path, previewModel.id));
      dir.createSync(recursive: true);
      File(p.join(dir.path, 'tokens.txt')).writeAsStringSync('tokens');
      File(p.join(dir.path, 'model.onnx')).writeAsStringSync('onnx');

      fakeIsolate = FakeIsolateService()
        ..responses['loadPreview'] = {
          'sampleRate': 22050,
          'speakerCount': 1,
        }
        ..responses['loadModel'] = {
          'sampleRate': 22050,
          'speakerCount': 1,
        }
        ..responses['generateToFile'] = {
          'outputPath': 'x.wav',
          'duration': 1.5,
          'sampleRate': 22050,
          'waveform': <double>[],
        }
        ..responses['unloadPreview'] = true
        ..responses['unload'] = true;

      manager = TtsDownloadManager(
        backgroundDownloader: FakeDownloaderService(),
        pathService: fakePath,
        store: store,
        archiveExtractor: FakeExtractor(),
      );

      service = SherpaOnnxTtsService(
        downloadManager: manager,
        isolateService: fakeIsolate,
        pathService: fakePath,
        store: store,
        settingsService: SettingsService(storage: fakeStorage),
      );
      service.skipNativeBindingInit = true;
    });

    tearDown(() async {
      manager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadPreviewModel loads into the preview engine only', () async {
      expect(service.hasPreviewLoaded, isFalse);

      await service.loadPreviewModel(previewModel.id);

      // The command targets the preview engine slot, not the narration one.
      expect(fakeIsolate.commands.last['type'], 'loadPreview');
      expect(service.hasPreviewLoaded, isTrue);
      expect(service.previewModel?.id, previewModel.id);

      // The narration engine is untouched.
      expect(service.activeModel, isNull);
      expect(service.hasLoadedModel, isFalse);
    });

    test('loadModel still targets the narration engine', () async {
      await service.loadModel(previewModel.id);

      expect(fakeIsolate.commands.last['type'], 'loadModel');
      expect(service.activeModel?.id, previewModel.id);
      expect(service.hasLoadedModel, isTrue);
      expect(service.hasPreviewLoaded, isFalse);
    });

    test('generatePreviewToFile synthesizes with the preview engine', () async {
      await service.loadPreviewModel(previewModel.id);
      fakeIsolate.commands.clear();

      final out = await service.generatePreviewToFile(
        text: 'Hello.',
        outputPath: 'preview.wav',
      );

      final cmd = fakeIsolate.commands.last;
      expect(cmd['type'], 'generateToFile');
      expect(cmd['preview'], isTrue);
      expect(cmd['outputPath'], 'preview.wav');
      expect(out.duration, 1.5);
      expect(out.file.path, 'preview.wav');
    });

    test('generatePreviewToFile requires a preview model', () async {
      expect(
        () => service.generatePreviewToFile(
          text: 'Hello.',
          outputPath: 'preview.wav',
        ),
        throwsA(isA<TtsModelNotLoadedException>()),
      );
    });

    test('unloadPreviewModel releases the preview engine', () async {
      await service.loadPreviewModel(previewModel.id);
      fakeIsolate.commands.clear();

      await service.unloadPreviewModel();

      expect(fakeIsolate.commands.last['type'], 'unloadPreview');
      expect(service.hasPreviewLoaded, isFalse);
    });

    test('preview model must exist on disk and in the store', () async {
      await expectLater(
        service.loadPreviewModel('missing-model'),
        throwsA(isA<SherpaTtsException>()),
      );
      final isolateCalls = fakeIsolate.commands
          .where((c) => c['type'] == 'loadPreview')
          .length;
      expect(isolateCalls, 0);
    });
  });
}
