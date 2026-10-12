import 'package:readaway/src/core/services/tts/tts_models.dart';

/// Creates a fake [TtsVoiceOption] with sensible defaults.
TtsVoiceOption fakeTtsVoiceOption({
  String id = 'vits-piper-en_US-amy-low',
  String label = 'Amy',
  String languageCode = 'en_US',
  TtsEngineKind engine = TtsEngineKind.sherpaOnnx,
}) => TtsVoiceOption(
  id: id,
  label: label,
  languageCode: languageCode,
  engine: engine,
);
