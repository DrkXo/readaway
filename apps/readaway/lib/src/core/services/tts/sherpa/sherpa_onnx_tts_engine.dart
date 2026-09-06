import 'package:injectable/injectable.dart';

import '../tts_engine.dart';
import '../tts_models.dart';
import 'sherpa_onnx_tts_service.dart';

@lazySingleton
class SherpaOnnxTtsEngine implements TtsEngine {
  final SherpaOnnxTtsService _sherpaService;

  SherpaOnnxTtsEngine(this._sherpaService);

  @override
  TtsEngineKind get kind => TtsEngineKind.sherpaOnnx;

  @override
  bool get isReady => _sherpaService.hasLoadedModel;

  @override
  Future<void> initialize() async {
    await _sherpaService.ensureInitialized();
  }

  @override
  Future<void> dispose() async {
    await _sherpaService.releaseIsolate();
  }

  @override
  Future<List<TtsVoiceOption>> getAvailableVoices() async {
    final downloaded = await _sherpaService.getDownloadedModels();
    final result = <TtsVoiceOption>[];
    for (final m in downloaded) {
      if (m.speakerCount > 1) {
        for (var spk = 0; spk < m.speakerCount; spk++) {
          result.add(
            TtsVoiceOption(
              engine: TtsEngineKind.sherpaOnnx,
              id: m.id,
              label: '${m.displayName} (Voice $spk)',
              languageCode: m.languageCode,
              sherpaSpeakerId: spk,
              previewAudioUrl: m.previewAudioUrl,
            ),
          );
        }
      } else {
        result.add(
          TtsVoiceOption(
            engine: TtsEngineKind.sherpaOnnx,
            id: m.id,
            label: m.displayName,
            languageCode: m.languageCode,
            sherpaSpeakerId: m.speakerCount > 0 ? 0 : null,
            previewAudioUrl: m.previewAudioUrl,
          ),
        );
      }
    }
    return result;
  }

  @override
  Future<TtsSynthesisResult> synthesizeToFile({
    required String text,
    required String outputPath,
    required TtsVoiceOption voice,
    double speed = 1.0,
    double pitch = 1.0,
  }) async {
    if (_sherpaService.activeModel?.id != voice.id) {
      await _sherpaService.loadModel(voice.id);
    }

    final result = await _sherpaService.generateToFile(
      text: text,
      outputPath: outputPath,
      speakerId: voice.sherpaSpeakerId ?? 0,
      speed: speed,
    );

    return TtsSynthesisResult(
      file: result.file,
      duration: result.duration,
      sampleRate: _sherpaService.sampleRate,
      waveform: result.waveform,
    );
  }
}
