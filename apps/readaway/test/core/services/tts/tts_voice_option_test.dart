import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';

void main() {
  group('TtsVoiceOption', () {
    test('storageKey formatting', () {
      const singleSpeaker = TtsVoiceOption(
        engine: TtsEngineKind.sherpaOnnx,
        id: 'vits-piper-en_US-ryan-high',
        label: 'Ryan',
      );
      expect(singleSpeaker.storageKey, 'vits-piper-en_US-ryan-high');

      const multiSpeaker = TtsVoiceOption(
        engine: TtsEngineKind.sherpaOnnx,
        id: 'vits-piper-en_US-ryan-high',
        label: 'Ryan (Voice 0)',
        sherpaSpeakerId: 0,
      );
      expect(multiSpeaker.storageKey, 'vits-piper-en_US-ryan-high@0');

      const multiSpeakerTwo = TtsVoiceOption(
        engine: TtsEngineKind.sherpaOnnx,
        id: 'kokoro-multi',
        label: 'Kokoro (Voice 2)',
        sherpaSpeakerId: 2,
      );
      expect(multiSpeakerTwo.storageKey, 'kokoro-multi@2');
    });

    test('matchesKey matching rules', () {
      const singleSpeaker = TtsVoiceOption(
        engine: TtsEngineKind.sherpaOnnx,
        id: 'vits-piper-en_US-ryan-high',
        label: 'Ryan',
      );
      expect(singleSpeaker.matchesKey('vits-piper-en_US-ryan-high'), isTrue);
      expect(singleSpeaker.matchesKey('vits-piper-en_US-ryan-high@0'), isFalse);
      expect(singleSpeaker.matchesKey('vits-piper-en_US-other'), isFalse);

      const multiSpeakerZero = TtsVoiceOption(
        engine: TtsEngineKind.sherpaOnnx,
        id: 'vits-piper-en_US-ryan-high',
        label: 'Ryan (Voice 0)',
        sherpaSpeakerId: 0,
      );
      expect(
        multiSpeakerZero.matchesKey('vits-piper-en_US-ryan-high@0'),
        isTrue,
      );
      expect(multiSpeakerZero.matchesKey('vits-piper-en_US-ryan-high'), isTrue);
      expect(
        multiSpeakerZero.matchesKey('vits-piper-en_US-ryan-high@1'),
        isFalse,
      );

      const multiSpeakerOne = TtsVoiceOption(
        engine: TtsEngineKind.sherpaOnnx,
        id: 'vits-piper-en_US-ryan-high',
        label: 'Ryan (Voice 1)',
        sherpaSpeakerId: 1,
      );
      expect(
        multiSpeakerOne.matchesKey('vits-piper-en_US-ryan-high@1'),
        isTrue,
      );
      expect(
        multiSpeakerOne.matchesKey('vits-piper-en_US-ryan-high@0'),
        isFalse,
      );
      expect(multiSpeakerOne.matchesKey('vits-piper-en_US-ryan-high'), isFalse);
    });
  });
}
