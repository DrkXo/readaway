import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readaway/src/core/services/services.dart';
import 'package:readaway/src/features/settings/data/repositories/tts_model_repository_impl.dart';

class MockSherpaOnnxTtsService extends Mock implements SherpaOnnxTtsService {}

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockAppPathService extends Mock implements AppPathService {}

void main() {
  group('TtsModelRepositoryImpl playPreview', () {
    late MockSherpaOnnxTtsService mockTtsService;
    late MockAudioPlayerService mockAudioPlayer;
    late MockAppPathService mockPathService;
    late TtsModelRepositoryImpl repository;
    late Directory tempCacheDir;

    setUp(() async {
      mockTtsService = MockSherpaOnnxTtsService();
      mockAudioPlayer = MockAudioPlayerService();
      mockPathService = MockAppPathService();
      tempCacheDir = await Directory.systemTemp.createTemp('tts_cache_test_');

      when(() => mockPathService.getTtsAudioCacheDirectory())
          .thenAnswer((_) async => tempCacheDir);

      repository = TtsModelRepositoryImpl(
        mockTtsService,
        mockAudioPlayer,
        mockPathService,
      );
    });

    tearDown(() async {
      if (await tempCacheDir.exists()) {
        await tempCacheDir.delete(recursive: true);
      }
    });

    test('plays remote preview URL when model is not downloaded', () async {
      const model = SherpaTtsModelInfo(
        id: 'vits-piper-en_US-amy-low',
        displayName: 'Amy (low)',
        languageCode: 'en-US',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: 'https://example.com/model.tar.bz2',
        approxSizeMb: 25.0,
        previewAudioUrl:
            'https://huggingface.co/csukuangfj/sherpa-onnx-tts-samples/resolve/main/piper/mp3/en_US/vits-piper-en_US-amy-low/0.mp3',
      );

      when(() => mockTtsService.availableModels).thenReturn([model]);
      when(() => mockTtsService.isModelDownloaded(any()))
          .thenAnswer((_) async => false);
      when(() => mockAudioPlayer.playPreviewUrl(
            any(),
            cacheFilePath: any(named: 'cacheFilePath'),
          )).thenAnswer((_) async {});

      final result = await repository.playPreview('vits-piper-en_US-amy-low').run();

      expect(result.isRight(), isTrue);
      verify(() => mockAudioPlayer.playPreviewUrl(
            model.previewAudioUrl!,
            cacheFilePath: any(named: 'cacheFilePath'),
          )).called(1);
    });

    test('stops preview player via stopPreview', () async {
      when(() => mockAudioPlayer.stopPreview()).thenAnswer((_) async {});

      final result = await repository.stopPreview().run();

      expect(result.isRight(), isTrue);
      verify(() => mockAudioPlayer.stopPreview()).called(1);
    });
  });
}
