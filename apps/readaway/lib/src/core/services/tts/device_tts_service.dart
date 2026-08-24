part of '../services.dart';

/// Injectable wrapper around the platform's built-in TTS engine
/// (`flutter_tts` → AVSpeechSynthesizer on iOS, TextToSpeech on Android,
/// etc.). This is the "free, always available, no download" option that
/// sits alongside [SherpaOnnxTtsService] to give the reader maximum choice.
///
/// Unlike the sherpa engine, device TTS can't reliably export raw PCM/WAV
/// on every platform, so this service is playback-only: it speaks directly
/// through the OS, rather than handing back samples for a shared player.
/// [ReaderTtsController] accounts for that difference.
@singleton
class DeviceTtsService {
  final FlutterTts _flutterTts = FlutterTts();

  final _stateController = StreamController<TtsPlaybackEvent>.broadcast();
  Stream<TtsPlaybackEvent> get events => _stateController.stream;

  bool _initialized = false;

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool isSupported() => _initialized;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (_initialized || isDesktop) return;
    _initialized = true;

    _flutterTts.setStartHandler(() {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));
    });
    _flutterTts.setCompletionHandler(() {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
    });
    _flutterTts.setPauseHandler(() {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.paused));
    });
    _flutterTts.setErrorHandler((msg) {
      _stateController.add(
        TtsPlaybackEvent(TtsPlaybackState.error, message: msg.toString()),
      );
    });

    // Lets `pause()` actually pause instead of just stopping.
    await _flutterTts.awaitSpeakCompletion(true);
  }

  /// Every voice the OS currently reports as installed. Availability
  /// varies wildly by device/OS language packs — always show this list
  /// live rather than hardcoding it.
  Future<List<TtsVoiceOption>> getVoices() async {
    final raw = await _flutterTts.getVoices;
    final result = <TtsVoiceOption>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is Map) {
          final name = v['name']?.toString();
          final locale = v['locale']?.toString();
          if (name == null) continue;
          result.add(
            TtsVoiceOption(
              engine: TtsEngineKind.device,
              id: name,
              label: locale != null ? '$name ($locale)' : name,
              languageCode: locale,
            ),
          );
        }
      }
    }
    return result;
  }

  Future<void> setVoice(TtsVoiceOption voice) async {
    assert(voice.engine == TtsEngineKind.device);
    await _flutterTts.setVoice({
      'name': voice.id,
      if (voice.languageCode != null) 'locale': voice.languageCode!,
    });
  }

  /// 0.0 (slowest) - 1.0 (fastest); platform-normalized by flutter_tts.
  Future<void> setRate(double rate) => _flutterTts.setSpeechRate(rate);

  /// 0.5 - 2.0, 1.0 is normal.
  Future<void> setPitch(double pitch) => _flutterTts.setPitch(pitch);

  /// 0.0 - 1.0
  Future<void> setVolume(double volume) => _flutterTts.setVolume(volume);

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _flutterTts.speak(text);
  }

  Future<void> pause() => _flutterTts.pause();

  Future<void> stop() => _flutterTts.stop();

  @disposeMethod
  Future<void> dispose() async {
    await _stateController.close();
  }
}
