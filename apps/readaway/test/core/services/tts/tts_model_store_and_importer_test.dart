import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/storage/hive/app_storage_service.dart';
import 'package:readaway/src/core/services/tts/extractor/tts_archive_extractor.dart';
import 'package:readaway/src/core/services/tts/importer/custom_tts_model_importer_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SherpaTtsModelInfo Update & Custom Flags', () {
    test('hasUpdateAvailable detects checksum differences', () {
      const installed = SherpaTtsModelInfo(
        id: 'vits-piper-en_US-amy-low',
        displayName: 'Amy (Low)',
        languageCode: 'en-US',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: 'https://example.com/amy.tar.bz2',
        approxSizeMb: 15.0,
        installedChecksum: 'aaaa1111',
      );

      const latestSame = SherpaTtsModelInfo(
        id: 'vits-piper-en_US-amy-low',
        displayName: 'Amy (Low)',
        languageCode: 'en-US',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: 'https://example.com/amy.tar.bz2',
        approxSizeMb: 15.0,
        installedChecksum: 'aaaa1111',
      );

      const latestNew = SherpaTtsModelInfo(
        id: 'vits-piper-en_US-amy-low',
        displayName: 'Amy (Low)',
        languageCode: 'en-US',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: 'https://example.com/amy.tar.bz2',
        approxSizeMb: 15.0,
        installedChecksum: 'bbbb2222',
      );

      expect(installed.hasUpdateAvailable(latestSame), isFalse);
      expect(installed.hasUpdateAvailable(latestNew), isTrue);
    });

    test('custom models never report update available', () {
      const customModel = SherpaTtsModelInfo(
        id: 'custom_my_voice_123',
        displayName: 'My Custom Voice',
        languageCode: 'en-US',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: '',
        approxSizeMb: 25.0,
        isCustom: true,
      );

      const remoteSameId = SherpaTtsModelInfo(
        id: 'custom_my_voice_123',
        displayName: 'Different Voice',
        languageCode: 'en-US',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: 'https://example.com',
        approxSizeMb: 50.0,
        installedChecksum: 'xyz',
      );

      expect(customModel.hasUpdateAvailable(remoteSameId), isFalse);
    });
  });

  group('TtsModelStore with Installed Model Metadata', () {
    late FakeAppStorageService fakeStorage;
    late TtsModelStore store;

    setUp(() {
      fakeStorage = FakeAppStorageService();
      store = TtsModelStore(storage: fakeStorage);
    });

    test('saves and loads full installed model info', () async {
      const model = SherpaTtsModelInfo(
        id: 'custom_model_1',
        displayName: 'Custom Voice 1',
        languageCode: 'fr-FR',
        languageLabel: 'French',
        type: SherpaTtsModelType.matcha,
        downloadUrl: '',
        approxSizeMb: 30.5,
        isCustom: true,
        speakerCount: 4,
      );

      await store.saveInstalledModel(model);

      final installed = store.loadInstalledModels();
      expect(installed.containsKey('custom_model_1'), isTrue);
      expect(installed['custom_model_1']?.displayName, 'Custom Voice 1');
      expect(installed['custom_model_1']?.type, SherpaTtsModelType.matcha);
      expect(installed['custom_model_1']?.isCustom, isTrue);
      expect(installed['custom_model_1']?.speakerCount, 4);

      expect(store.loadDownloadedIds(), contains('custom_model_1'));

      final lookedUp = store.byId('custom_model_1');
      expect(lookedUp, isNotNull);
      expect(lookedUp?.displayName, 'Custom Voice 1');

      await store.removeInstalledModel('custom_model_1');
      expect(store.loadInstalledModels().isEmpty, isTrue);
      expect(store.loadDownloadedIds().isEmpty, isTrue);
    });
  });

  group('CustomTtsModelImporterService Directory Inspection', () {
    late Directory tempDir;
    late TtsModelStore store;
    late CustomTtsModelImporterService importer;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('custom_tts_test_');
      final fakeStorage = FakeAppStorageService();
      store = TtsModelStore(storage: fakeStorage);
      final fakePath = FakeAppPathService(tempDir);

      importer = CustomTtsModelImporterService(
        archiveExtractor: const TtsArchiveExtractor(),
        pathService: fakePath,
        store: store,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('detects valid VITS model folder', () async {
      final modelFolder = Directory('${tempDir.path}/test_vits_model');
      await modelFolder.create();
      await File('${modelFolder.path}/model.onnx').writeAsString('fake onnx');
      await File('${modelFolder.path}/tokens.txt').writeAsString('fake tokens');

      final inspection = await importer.inspectSource(modelFolder.path);

      expect(inspection.hasTokens, isTrue);
      expect(inspection.onnxFiles, contains('model.onnx'));
      expect(inspection.detectedType, SherpaTtsModelType.vits);
    });

    test('detects Kokoro model folder when voices.bin is present', () async {
      final modelFolder = Directory('${tempDir.path}/test_kokoro_model');
      await modelFolder.create();
      await File('${modelFolder.path}/model.onnx').writeAsString('fake onnx');
      await File('${modelFolder.path}/tokens.txt').writeAsString('fake tokens');
      await File('${modelFolder.path}/voices.bin').writeAsString('fake bin');

      final inspection = await importer.inspectSource(modelFolder.path);

      expect(inspection.hasTokens, isTrue);
      expect(inspection.hasVoicesBin, isTrue);
      expect(inspection.detectedType, SherpaTtsModelType.kokoro);
    });

    test('throws exception when tokens.txt is missing', () async {
      final modelFolder = Directory('${tempDir.path}/test_invalid_model');
      await modelFolder.create();
      await File('${modelFolder.path}/model.onnx').writeAsString('fake onnx');

      expect(
        () => importer.inspectSource(modelFolder.path),
        throwsA(isA<SherpaTtsException>()),
      );
    });

    test('throws exception when no .onnx files exist', () async {
      final modelFolder = Directory('${tempDir.path}/test_invalid_model2');
      await modelFolder.create();
      await File('${modelFolder.path}/tokens.txt').writeAsString('fake tokens');

      expect(
        () => importer.inspectSource(modelFolder.path),
        throwsA(isA<SherpaTtsException>()),
      );
    });

    test('imports model and saves full metadata into store', () async {
      final modelFolder = Directory('${tempDir.path}/test_import_model');
      await modelFolder.create();
      await File('${modelFolder.path}/model.onnx').writeAsString('onnx content');
      await File('${modelFolder.path}/tokens.txt').writeAsString('tokens content');

      final inspection = await importer.inspectSource(modelFolder.path);
      final imported = await importer.importModel(
        inspection: inspection,
        displayName: 'My Test Voice',
        languageCode: 'de-DE',
        languageLabel: 'German',
      );

      expect(imported.displayName, 'My Test Voice');
      expect(imported.languageCode, 'de-DE');
      expect(imported.languageLabel, 'German');
      expect(imported.isCustom, isTrue);

      final fromStore = store.byId(imported.id);
      expect(fromStore, isNotNull);
      expect(fromStore?.displayName, 'My Test Voice');
      expect(fromStore?.isCustom, isTrue);
    });
  });
}
