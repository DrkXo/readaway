import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/services.dart';

void main() {
  group('SherpaTtsModelInfo previewAudioUrl', () {
    test('constructs valid preview audio URL for piper models', () {
      const model = SherpaTtsModelInfo(
        id: 'vits-piper-en_US-amy-low',
        displayName: 'Amy (low)',
        languageCode: 'en-US',
        languageLabel: 'English',
        type: SherpaTtsModelType.vits,
        downloadUrl: 'https://example.com/vits-piper-en_US-amy-low.tar.bz2',
        approxSizeMb: 25.0,
        previewAudioUrl:
            'https://huggingface.co/csukuangfj/sherpa-onnx-tts-samples/resolve/main/piper/mp3/en_US/vits-piper-en_US-amy-low/0.mp3',
      );

      expect(model.previewAudioUrl, isNotNull);
      expect(
        model.previewAudioUrl,
        contains('piper/mp3/en_US/vits-piper-en_US-amy-low/0.mp3'),
      );
    });

    test('constructs valid preview audio URL for kokoro models', () {
      const model = SherpaTtsModelInfo(
        id: 'kokoro-multi-lang-v1_0',
        displayName: 'Kokoro 1.0 (multi-language)',
        languageCode: 'multi',
        languageLabel: 'Multiple languages',
        type: SherpaTtsModelType.kokoro,
        downloadUrl: 'https://example.com/kokoro-multi-lang-v1_0.tar.bz2',
        approxSizeMb: 85.0,
        previewAudioUrl:
            'https://huggingface.co/csukuangfj/sherpa-onnx-tts-samples/resolve/main/kokoro/v1.0/mp3/0-af_alloy.mp3',
      );

      expect(model.previewAudioUrl, isNotNull);
      expect(model.previewAudioUrl, contains('kokoro/v1.0/mp3/0-af_alloy.mp3'));
    });
  });
}
