part of '../services.dart';

@singleton
class ReaderTtsController {
  ReaderTtsController(
    this._deviceTts,
    this._sherpaTts,
    this._audio,
    this._textChunker,
  );

  final DeviceTtsService _deviceTts;
  final SherpaOnnxTtsService _sherpaTts;
  final JustAudioService _audio;
  final TextChunker _textChunker;

  TtsVoiceOption? _voice;
  double _rate = 1.0;
  // ignore: unused_field
  double _pitch = 1.0;

  List<TtsChunk> _queue = [];
  int _queueIndex = -1;
  bool _stopRequested = false;

  final _stateController = StreamController<TtsPlaybackEvent>.broadcast();
  final _chunkController = StreamController<TtsChunk>.broadcast();

  /// Playback lifecycle events (playing/paused/stopped/error), merged from
  /// whichever engine is active.
  Stream<TtsPlaybackEvent> get playbackState => _stateController.stream;

  /// Fires with the sentence currently being spoken — use this to drive
  /// read-along highlighting in the reader UI.
  Stream<TtsChunk> get currentChunk => _chunkController.stream;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    await _deviceTts.init();
    _deviceTts.events.listen(_stateController.add);
  }

  // ---------------------------------------------------------------------
  // Voice selection — this is where "maximum choice" is exposed.
  // ---------------------------------------------------------------------

  /// All device voices *plus* every already-downloaded sherpa-onnx voice.
  /// Feed this straight into a voice picker; call [availableSherpaModels]
  /// separately if you also want to show voices that aren't downloaded
  /// yet (with a "download" affordance).
  Future<List<TtsVoiceOption>> getInstalledVoices() async {
    final deviceVoices = await _deviceTts.getVoices();
    final sherpaModels = await _sherpaTts.getDownloadedModels();
    final sherpaVoices = sherpaModels.map(
      (m) => TtsVoiceOption(
        engine: TtsEngineKind.sherpaOnnx,
        id: m.id,
        label: m.displayName,
        languageCode: m.languageCode,
      ),
    );
    return [...deviceVoices, ...sherpaVoices];
  }

  /// The full catalog of downloadable sherpa-onnx voices (downloaded or
  /// not) — for a "browse more voices" screen.
  List<SherpaTtsModelInfo> get availableSherpaModels =>
      _sherpaTts.availableModels;

  Stream<ModelDownloadProgress> downloadSherpaVoice(SherpaTtsModelInfo model) =>
      _sherpaTts.downloadModel(model);

  Future<void> deleteSherpaVoice(String modelId) =>
      _sherpaTts.deleteModel(modelId);

  Future<void> setVoice(TtsVoiceOption voice) async {
    _voice = voice;
    switch (voice.engine) {
      case TtsEngineKind.device:
        await _deviceTts.setVoice(voice);
        break;
      case TtsEngineKind.sherpaOnnx:
        await _sherpaTts.loadModel(voice.id);
        break;
    }
  }

  TtsVoiceOption? get currentVoice => _voice;

  Future<void> setRate(double rate) async {
    _rate = rate;
    if (_voice?.engine == TtsEngineKind.device) {
      await _deviceTts.setRate(rate.clamp(0.0, 1.0));
    }
    // sherpa's `speed` multiplier is applied per-generate() call below.
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    if (_voice?.engine == TtsEngineKind.device) {
      await _deviceTts.setPitch(pitch);
    }
    // sherpa-onnx offline TTS does not expose a runtime pitch knob.
  }

  // ---------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------

  /// Splits [text] into sentences and reads them in order, emitting
  /// [currentChunk] as each one starts. Call [stop] to cancel.
  Future<void> playText(String text, {int startAtChunkIndex = 0}) async {
    if (_voice == null) {
      _stateController.add(
        const TtsPlaybackEvent(
          TtsPlaybackState.error,
          message: 'No voice selected. Call setVoice() first.',
        ),
      );
      return;
    }

    _stopRequested = false;
    _queue = _textChunker.chunkSentences(text);
    _queueIndex = startAtChunkIndex - 1;

    await _playNext();
  }

  Future<void> _playNext() async {
    if (_stopRequested) return;
    _queueIndex++;
    if (_queueIndex >= _queue.length) {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
      return;
    }

    final chunk = _queue[_queueIndex];
    _chunkController.add(chunk);
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));

    final voice = _voice!;
    if (voice.engine == TtsEngineKind.device) {
      // flutter_tts's completion handler drives the next chunk. Only one
      // listener should be active at a time, so replace any previous one.
      await _deviceQueueSub?.cancel();
      _deviceQueueSub = _deviceTts.events.listen(_onDeviceEventForQueue);
      await _deviceTts.speak(chunk.text);
    } else {
      await _playSherpaChunk(chunk, voice);
    }
  }

  StreamSubscription<TtsPlaybackEvent>? _deviceQueueSub;

  void _onDeviceEventForQueue(TtsPlaybackEvent event) {
    if (event.state == TtsPlaybackState.stopped && !_stopRequested) {
      unawaited(_deviceQueueSub?.cancel());
      unawaited(_playNext());
    }
  }

  Future<void> _playSherpaChunk(TtsChunk chunk, TtsVoiceOption voice) async {
    try {
      final audio = _sherpaTts.generate(
        text: chunk.text,
        speakerId: voice.sherpaSpeakerId ?? 0,
        speed: _rate <= 0 ? 1.0 : _rate,
      );
      // Attach the completion listener before playback starts so a very
      // short clip can't finish before we're listening.
      final completer = Completer<void>();
      late final StreamSubscription sub;
      sub = _audio.playerState.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          sub.cancel();
          completer.complete();
        }
      });
      await _audio.playPcm(audio);
      await completer.future;
      if (!_stopRequested) await _playNext();
    } catch (e) {
      _stateController.add(
        TtsPlaybackEvent(TtsPlaybackState.error, message: e.toString()),
      );
    }
  }

  Future<void> pause() async {
    if (_voice?.engine == TtsEngineKind.device) {
      await _deviceTts.pause();
    } else {
      await _audio.pause();
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.paused));
    }
  }

  Future<void> resume() async {
    if (_voice?.engine == TtsEngineKind.device) {
      // flutter_tts has no resume; re-speak the current chunk.
      if (_queueIndex >= 0 && _queueIndex < _queue.length) {
        await _deviceTts.speak(_queue[_queueIndex].text);
      }
    } else {
      await _audio.resume();
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));
    }
  }

  Future<void> stop() async {
    _stopRequested = true;
    _deviceQueueSub?.cancel();
    await _deviceTts.stop();
    await _audio.stop();
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
  }

  Future<void> skipToNextSentence() async {
    if (_voice?.engine == TtsEngineKind.device) {
      await _deviceTts.stop();
    } else {
      await _audio.stop();
    }
    await _playNext();
  }

  @disposeMethod
  void dispose() {
    _stateController.close();
    _chunkController.close();
  }
}
