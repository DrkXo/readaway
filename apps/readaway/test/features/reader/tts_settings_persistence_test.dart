import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readaway/src/core/models/models.dart';
import 'package:readaway/src/core/services/audio/audio_player_service.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/tts/tts_chunker_service.dart';
import 'package:readaway/src/core/services/tts/tts_controller_service.dart';
import 'package:readaway/src/core/services/tts/tts_engine.dart';
import 'package:rxdart/rxdart.dart';

class MockSettingsService extends Mock implements SettingsService {}
class MockAudioPlayerService extends Mock implements AudioPlayerService {}
class MockChunkingService extends Mock implements TtsChunkingService {}
class MockPathService extends Mock implements AppPathService {}
class MockEngineRegistry extends Mock implements TtsEngineRegistry {}

void main() {
  group('GlobalViewSettings TTS serialization', () {
    test('defaults to 1.0 for ttsRate and ttsPitch', () {
      const settings = GlobalViewSettings();
      expect(settings.ttsRate, 1.0);
      expect(settings.ttsPitch, 1.0);
    });

    test('serializes and deserializes ttsPitch and ttsRate correctly', () {
      const settings = GlobalViewSettings(
        ttsRate: 1.25,
        ttsPitch: 1.1,
      );
      final json = settings.toJson();
      expect(json['ttsRate'], 1.25);
      expect(json['ttsPitch'], 1.1);

      final deserialized = GlobalViewSettings.fromJson(json);
      expect(deserialized.ttsRate, 1.25);
      expect(deserialized.ttsPitch, 1.1);
    });

    test('defaults ttsPitch to 1.0 when missing from json', () {
      final json = <String, dynamic>{
        'ttsRate': 1.5,
      };
      final deserialized = GlobalViewSettings.fromJson(json);
      expect(deserialized.ttsRate, 1.5);
      expect(deserialized.ttsPitch, 1.0);
    });
  });

  group('TtsControllerService rate and pitch persistence', () {
    late MockSettingsService mockSettingsService;
    late MockAudioPlayerService mockAudioPlayer;
    late MockChunkingService mockChunkingService;
    late MockPathService mockPathService;
    late MockEngineRegistry mockEngineRegistry;
    late BehaviorSubject<Settings> settingsSubject;

    setUp(() {
      mockSettingsService = MockSettingsService();
      mockAudioPlayer = MockAudioPlayerService();
      mockChunkingService = MockChunkingService();
      mockPathService = MockPathService();
      mockEngineRegistry = MockEngineRegistry();
      settingsSubject = BehaviorSubject<Settings>();

      when(() => mockSettingsService.changes).thenAnswer((_) => settingsSubject.stream);
      when(() => mockAudioPlayer.setSpeed(any())).thenAnswer((_) async {});
      when(() => mockAudioPlayer.setPitch(any())).thenAnswer((_) async {});
      when(() => mockChunkingService.stop()).thenAnswer((_) async {});
      when(() => mockEngineRegistry.disposeAll()).thenAnswer((_) async {});
      when(() => mockAudioPlayer.stopSession()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await settingsSubject.close();
    });

    test('initializes rate and pitch from SettingsService', () {
      final initialSettings = Settings(
        globalViewSettings: const GlobalViewSettings(
          ttsRate: 1.5,
          ttsPitch: 1.2,
        ),
      );
      when(() => mockSettingsService.settings).thenReturn(initialSettings);

      final controller = TtsControllerService(
        mockEngineRegistry,
        mockAudioPlayer,
        mockChunkingService,
        mockPathService,
        mockSettingsService,
      );

      expect(controller.rate, 1.5);
      expect(controller.pitch, 1.2);
    });

    test('setRate updates rate, audioPlayer speed, and calls scheduleSave', () async {
      final initialSettings = Settings(
        globalViewSettings: const GlobalViewSettings(
          ttsRate: 1.0,
          ttsPitch: 1.0,
        ),
      );
      when(() => mockSettingsService.settings).thenReturn(initialSettings);
      when(() => mockSettingsService.scheduleSave(any())).thenReturn(null);

      final controller = TtsControllerService(
        mockEngineRegistry,
        mockAudioPlayer,
        mockChunkingService,
        mockPathService,
        mockSettingsService,
      );

      await controller.setRate(1.75);

      expect(controller.rate, 1.75);
      verify(() => mockAudioPlayer.setSpeed(1.75)).called(1);
      final captured = verify(() => mockSettingsService.scheduleSave(captureAny())).captured;
      expect(captured.length, 1);
      final savedSettings = captured.first as Settings;
      expect(savedSettings.globalViewSettings.ttsRate, 1.75);
    });

    test('setPitch updates pitch, audioPlayer pitch, and calls scheduleSave', () async {
      final initialSettings = Settings(
        globalViewSettings: const GlobalViewSettings(
          ttsRate: 1.0,
          ttsPitch: 1.0,
        ),
      );
      when(() => mockSettingsService.settings).thenReturn(initialSettings);
      when(() => mockSettingsService.scheduleSave(any())).thenReturn(null);

      final controller = TtsControllerService(
        mockEngineRegistry,
        mockAudioPlayer,
        mockChunkingService,
        mockPathService,
        mockSettingsService,
      );

      await controller.setPitch(1.3);

      expect(controller.pitch, 1.3);
      verify(() => mockAudioPlayer.setPitch(1.3)).called(1);
      final captured = verify(() => mockSettingsService.scheduleSave(captureAny())).captured;
      expect(captured.length, 1);
      final savedSettings = captured.first as Settings;
      expect(savedSettings.globalViewSettings.ttsPitch, 1.3);
    });
  });
}
