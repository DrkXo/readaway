import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/models/models.dart';
import 'package:readaway/src/core/services/tts/sherpa/sherpa_isolate_worker_service.dart';

void main() {
  group('Sherpa TTS Config Builders', () {
    test('buildGenerationConfigFromMessage parses default and custom params', () {
      final defaultGen = buildGenerationConfigFromMessage({});
      expect(defaultGen.sid, 0);
      expect(defaultGen.speed, 1.0);
      expect(defaultGen.silenceScale, 0.5);
      expect(defaultGen.numSteps, 5);

      final customGen = buildGenerationConfigFromMessage({
        'speakerId': 3,
        'speed': 1.25,
        'silenceScale': 0.15,
        'numSteps': 8,
      });
      expect(customGen.sid, 3);
      expect(customGen.speed, 1.25);
      expect(customGen.silenceScale, 0.15);
      expect(customGen.numSteps, 8);
    });

    test('buildSherpaConfigFromMessage creates VITS config with fine-tuning parameters', () {
      final vitsConfig = buildSherpaConfigFromMessage({
        'modelType': 'vits',
        'modelPath': '/path/to/model.onnx',
        'tokens': '/path/to/tokens.txt',
        'lexicon': '/path/to/lexicon.txt',
        'dataDir': '/path/to/espeak-ng-data',
        'dictDir': '/path/to/dict',
        'noiseScale': 0.5,
        'noiseScaleW': 0.7,
        'lengthScale': 1.1,
        'numThreads': 4,
        'debug': true,
      });

      expect(vitsConfig.numThreads, 4);
      expect(vitsConfig.debug, isTrue);
      expect(vitsConfig.provider, 'cpu');
      expect(vitsConfig.vits.model, '/path/to/model.onnx');
      expect(vitsConfig.vits.tokens, '/path/to/tokens.txt');
      expect(vitsConfig.vits.lexicon, '/path/to/lexicon.txt');
      expect(vitsConfig.vits.dataDir, '/path/to/espeak-ng-data');
      expect(vitsConfig.vits.dictDir, '/path/to/dict');
      expect(vitsConfig.vits.noiseScale, 0.5);
      expect(vitsConfig.vits.noiseScaleW, 0.7);
      expect(vitsConfig.vits.lengthScale, 1.1);
    });

    test('buildSherpaConfigFromMessage creates Matcha config with vocoder and parameters', () {
      final matchaConfig = buildSherpaConfigFromMessage({
        'modelType': 'matcha',
        'acousticPath': '/path/to/acoustic.onnx',
        'vocoderPath': '/path/to/vocos.onnx',
        'tokens': '/path/to/tokens.txt',
        'lexicon': '/path/to/lexicon.txt',
        'dataDir': '/path/to/espeak-ng-data',
        'noiseScale': 0.6,
        'lengthScale': 0.95,
        'numThreads': 2,
        'debug': false,
      });

      expect(matchaConfig.numThreads, 2);
      expect(matchaConfig.debug, isFalse);
      expect(matchaConfig.matcha.acousticModel, '/path/to/acoustic.onnx');
      expect(matchaConfig.matcha.vocoder, '/path/to/vocos.onnx');
      expect(matchaConfig.matcha.tokens, '/path/to/tokens.txt');
      expect(matchaConfig.matcha.noiseScale, 0.6);
      expect(matchaConfig.matcha.lengthScale, 0.95);
    });

    test('buildSherpaConfigFromMessage creates Kokoro config', () {
      final kokoroConfig = buildSherpaConfigFromMessage({
        'modelType': 'kokoro',
        'modelPath': '/path/to/kokoro.onnx',
        'voicesPath': '/path/to/voices.bin',
        'tokens': '/path/to/tokens.txt',
        'dataDir': '/path/to/espeak-ng-data',
        'lang': 'en-us',
        'lengthScale': 1.0,
      });

      expect(kokoroConfig.kokoro.model, '/path/to/kokoro.onnx');
      expect(kokoroConfig.kokoro.voices, '/path/to/voices.bin');
      expect(kokoroConfig.kokoro.tokens, '/path/to/tokens.txt');
      expect(kokoroConfig.kokoro.lang, 'en-us');
    });

    test('GlobalViewSettings has Sherpa TTS fine-tuning defaults and serializes cleanly', () {
      const gvs = GlobalViewSettings();
      expect(gvs.ttsSilenceScale, 0.5);
      expect(gvs.ttsNoiseScale, 0.667);
      expect(gvs.ttsNoiseScaleW, 0.8);
      expect(gvs.ttsLengthScale, 1.0);
      expect(gvs.ttsNumSteps, 5);

      final json = gvs.toJson();
      expect(json['ttsSilenceScale'], 0.5);
      expect(json['ttsNoiseScale'], 0.667);
      expect(json['ttsNoiseScaleW'], 0.8);
      expect(json['ttsLengthScale'], 1.0);
      expect(json['ttsNumSteps'], 5);

      final fromJson = GlobalViewSettings.fromJson(json);
      expect(fromJson, equals(gvs));
    });
  });
}
