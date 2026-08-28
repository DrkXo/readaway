part of '../services.dart';

@singleton
class ReaderTtsController {
  ReaderTtsController(
    this._sherpaTts,
    this._audio,
    this._textChunker,
  );

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

  /// Playback lifecycle events (playing/paused/stopped/error).
  Stream<TtsPlaybackEvent> get playbackState => _stateController.stream;

  /// Fires with the sentence currently being spoken — use this to drive
  /// read-along highlighting in the reader UI.
  Stream<TtsChunk> get currentChunk => _chunkController.stream;

  // ---------------------------------------------------------------------
  // Voice selection
  // ---------------------------------------------------------------------

  /// Every already-downloaded sherpa-onnx voice. Feed this straight into a
  /// voice picker; call [availableSherpaModels] separately if you also want
  /// to show voices that aren't downloaded yet (with a "download"
  /// affordance).
  Future<List<TtsVoiceOption>> getInstalledVoices() async {
    final sherpaModels = await _sherpaTts.getDownloadedModels();
    return sherpaModels
        .map(
          (m) => TtsVoiceOption(
            engine: TtsEngineKind.sherpaOnnx,
            id: m.id,
            label: m.displayName,
            languageCode: m.languageCode,
          ),
        )
        .toList();
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
    await _sherpaTts.loadModel(voice.id);
  }

  TtsVoiceOption? get currentVoice => _voice;

  Future<void> setRate(double rate) async {
    _rate = rate;
    // sherpa's `speed` multiplier is applied per-generate() call below.
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
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

    await _playSherpaChunk(chunk, _voice!);
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
    await _audio.pause();
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.paused));
  }

  Future<void> resume() async {
    await _audio.resume();
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));
  }

  Future<void> stop() async {
    _stopRequested = true;
    await _audio.stop();
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
  }

  Future<void> skipToNextSentence() async {
    await _audio.stop();
    await _playNext();
  }

  @disposeMethod
  void dispose() {
    _stateController.close();
    _chunkController.close();
  }
}
