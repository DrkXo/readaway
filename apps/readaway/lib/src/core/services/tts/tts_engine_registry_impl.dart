import 'package:injectable/injectable.dart';

import 'sherpa/sherpa_onnx_tts_engine.dart';
import 'tts_engine.dart';
import 'tts_models.dart';

@LazySingleton(as: TtsEngineRegistry)
class TtsEngineRegistryImpl implements TtsEngineRegistry {
  final Map<TtsEngineKind, TtsEngine> _engines = {};

  TtsEngineRegistryImpl(SherpaOnnxTtsEngine sherpaEngine) {
    registerEngine(sherpaEngine);
  }

  @override
  void registerEngine(TtsEngine engine) {
    _engines[engine.kind] = engine;
  }

  @override
  TtsEngine? getEngine(TtsEngineKind kind) => _engines[kind];

  @override
  TtsEngine getEngineForVoice(TtsVoiceOption voice) {
    final engine = _engines[voice.engine];
    if (engine == null) {
      throw SherpaTtsException('No TTS engine registered for ${voice.engine}');
    }
    return engine;
  }

  @override
  Future<List<TtsVoiceOption>> getAllInstalledVoices() async {
    final all = <TtsVoiceOption>[];
    for (final engine in _engines.values) {
      all.addAll(await engine.getAvailableVoices());
    }
    return all;
  }

  @override
  Future<void> initializeEngine(TtsEngineKind kind) async {
    await _engines[kind]?.initialize();
  }

  @override
  Future<void> disposeAll() async {
    for (final engine in _engines.values) {
      await engine.dispose();
    }
  }
}
