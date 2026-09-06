import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readaway/src/core/services/services.dart';
import 'package:readaway/src/core/services/tts/tts_engine_registry_impl.dart';

class MockSherpaOnnxTtsEngine extends Mock implements SherpaOnnxTtsEngine {}

class FakeEngine implements TtsEngine {
  @override
  final TtsEngineKind kind;
  bool initialized = false;
  bool disposed = false;

  FakeEngine(this.kind);

  @override
  bool get isReady => initialized;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<List<TtsVoiceOption>> getAvailableVoices() async {
    return [
      TtsVoiceOption(
        engine: kind,
        id: 'fake-voice',
        label: 'Fake Voice',
        languageCode: 'en-US',
      ),
    ];
  }

  @override
  Future<TtsSynthesisResult> synthesizeToFile({
    required String text,
    required String outputPath,
    required TtsVoiceOption voice,
    double speed = 1.0,
    double pitch = 1.0,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('TtsEngineRegistry', () {
    late MockSherpaOnnxTtsEngine mockSherpaEngine;
    late TtsEngineRegistryImpl registry;

    setUp(() {
      mockSherpaEngine = MockSherpaOnnxTtsEngine();
      when(() => mockSherpaEngine.kind).thenReturn(TtsEngineKind.sherpaOnnx);
      registry = TtsEngineRegistryImpl(mockSherpaEngine);
    });

    test('retrieves default registered Sherpa engine', () {
      final engine = registry.getEngine(TtsEngineKind.sherpaOnnx);
      expect(engine, equals(mockSherpaEngine));
    });

    test('registers and resolves device and cloud engines dynamically', () async {
      final deviceEngine = FakeEngine(TtsEngineKind.deviceVoice);
      final cloudEngine = FakeEngine(TtsEngineKind.microsoftTts);

      registry.registerEngine(deviceEngine);
      registry.registerEngine(cloudEngine);

      expect(registry.getEngine(TtsEngineKind.deviceVoice), equals(deviceEngine));
      expect(registry.getEngine(TtsEngineKind.microsoftTts), equals(cloudEngine));

      const voice = TtsVoiceOption(
        engine: TtsEngineKind.deviceVoice,
        id: 'device-voice-1',
        label: 'Device Voice',
      );

      final resolved = registry.getEngineForVoice(voice);
      expect(resolved, equals(deviceEngine));
    });

    test('disposes all registered engines on disposeAll', () async {
      final deviceEngine = FakeEngine(TtsEngineKind.deviceVoice);
      when(() => mockSherpaEngine.dispose()).thenAnswer((_) async {});

      registry.registerEngine(deviceEngine);
      await registry.disposeAll();

      verify(() => mockSherpaEngine.dispose()).called(1);
      expect(deviceEngine.disposed, isTrue);
    });
  });
}
