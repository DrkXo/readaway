part of '../services.dart';

@singleton
class ReaderTtsController {
  ReaderTtsController(
    this._sherpaTts,
    this._audio,
    this._textChunker,
  ) {
    _initQueuePipeline();
  }

  final SherpaOnnxTtsService _sherpaTts;
  final JustAudioService _audio;
  final TextChunker _textChunker;

  TtsVoiceOption? _voice;
  double _rate = 1.0;
  // ignore: unused_field
  double _pitch = 1.0;

  List<TtsChunk> _queue = [];
  int _queueIndex = -1;

  // Gapless-playback buffer
  TtsAudio? _prefetchedAudio;
  int _prefetchedIndex = -1;

  // Reactive Pipeline Controls
  final _playTriggerSubject = PublishSubject<int>();
  final _stateController = BehaviorSubject<TtsPlaybackEvent>.seeded(
    const TtsPlaybackEvent(TtsPlaybackState.stopped),
  );
  final _chunkController = BehaviorSubject<TtsChunk?>();

  StreamSubscription<void>? _pipelineSubscription;

  /// Playback lifecycle events (playing/paused/stopped/error).
  ValueStream<TtsPlaybackEvent> get playbackState => _stateController.stream;

  /// Fires with the sentence currently being spoken — use this to drive
  /// read-along highlighting in the reader UI.
  Stream<TtsChunk> get currentChunk => _chunkController.stream.whereNotNull();

  // ---------------------------------------------------------------------
  // Reactive Pipeline Setup
  // ---------------------------------------------------------------------

  void _initQueuePipeline() {
    // switchMap automatically cancels any ongoing sentence playback sequence
    // whenever a new index or command (-1 for stop) is pushed to the subject.
    _pipelineSubscription = _playTriggerSubject
        .switchMap((startIndex) => _playSequenceStream(startIndex))
        .listen(
          (_) {},
          onError: (Object error) {
            _stateController.add(
              TtsPlaybackEvent(
                TtsPlaybackState.error,
                message: error.toString(),
              ),
            );
          },
        );
  }

  Stream<void> _playSequenceStream(int startIndex) async* {
    if (startIndex < 0 || _queue.isEmpty || startIndex >= _queue.length) {
      _queueIndex = -1;
      _invalidatePrefetch();
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
      return;
    }

    _queueIndex = startIndex;

    while (_queueIndex < _queue.length) {
      final chunk = _queue[_queueIndex];
      _chunkController.add(chunk);
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));

      try {
        // Use pre-generated audio if index matches, otherwise synthesize
        // now. generate() now round-trips to the sherpa isolate, so this
        // has to be awaited — it's no longer a synchronous CPU call.
        final TtsAudio audio;
        if (_prefetchedIndex == _queueIndex && _prefetchedAudio != null) {
          audio = _prefetchedAudio!;
        } else {
          audio = await _sherpaTts.generate(
            text: chunk.text,
            speakerId: _voice?.sherpaSpeakerId ?? 0,
            speed: _rate <= 0 ? 1.0 : _rate,
          );
        }

        _invalidatePrefetch();

        // Start playing
        await _audio.playPcm(audio);

        // Kick off synthesis of the next chunk in the background while the
        // current clip plays — deliberately not awaited here.
        unawaited(_prefetchNext());

        // Await current clip audio completion
        await _audio.playerState.firstWhere(
          (state) => state.processingState == ProcessingState.completed,
        );

        _queueIndex++;
      } catch (e) {
        _stateController.add(
          TtsPlaybackEvent(TtsPlaybackState.error, message: e.toString()),
        );
        return;
      }
    }

    _queueIndex = -1;
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
  }

  // ---------------------------------------------------------------------
  // Queue introspection (for the player UI)
  // ---------------------------------------------------------------------

  /// The sentences queued for the current `playText` call.
  List<TtsChunk> get queue => List.unmodifiable(_queue);

  /// Number of sentences in the current queue.
  int get queueLength => _queue.length;

  /// Index of the sentence currently being spoken, or null when idle.
  int? get currentChunkIndex => _queueIndex >= 0 ? _queueIndex : null;

  // ---------------------------------------------------------------------
  // Voice selection
  // ---------------------------------------------------------------------

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

  List<SherpaTtsModelInfo> get availableSherpaModels =>
      _sherpaTts.availableModels;

  Stream<ModelDownloadProgress> downloadSherpaVoice(SherpaTtsModelInfo model) =>
      _sherpaTts.downloadModel(model);

  Future<void> deleteSherpaVoice(String modelId) =>
      _sherpaTts.deleteModel(modelId);

  Future<void> setVoice(TtsVoiceOption voice) async {
    if (_voice?.id == voice.id) return;
    _voice = voice;
    _invalidatePrefetch();
    if (_sherpaTts.activeModel?.id != voice.id) {
      await _sherpaTts.loadModel(voice.id);
    }
  }

  TtsVoiceOption? get currentVoice => _voice;

  Future<void> setRate(double rate) async {
    if (_rate == rate) return;
    _rate = rate;
    _invalidatePrefetch();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
  }

  // ---------------------------------------------------------------------
  // Playback Controls
  // ---------------------------------------------------------------------

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

    _queue = _textChunker.chunkSentences(text);
    _invalidatePrefetch();
    _playTriggerSubject.add(startAtChunkIndex);
  }

  /// Synthesizes the next queued chunk in the background so playback can
  /// stay gapless. Fire-and-forget from the caller's perspective, but the
  /// work itself is a real async isolate round trip now — so results are
  /// guarded against the queue having moved on (skip/stop/voice change)
  /// while the synthesis was in flight.
  Future<void> _prefetchNext() async {
    final nextIndex = _queueIndex + 1;
    if (nextIndex >= _queue.length) return;
    if (_prefetchedIndex == nextIndex) return;

    final chunk = _queue[nextIndex];
    _prefetchedIndex = nextIndex;
    try {
      final audio = await _sherpaTts.generate(
        text: chunk.text,
        speakerId: _voice?.sherpaSpeakerId ?? 0,
        speed: _rate <= 0 ? 1.0 : _rate,
      );
      // Only keep it if nothing invalidated/moved past this index while
      // we were awaiting the isolate.
      if (_prefetchedIndex == nextIndex) {
        _prefetchedAudio = audio;
      }
    } catch (_) {
      if (_prefetchedIndex == nextIndex) {
        _invalidatePrefetch();
      }
    }
  }

  void _invalidatePrefetch() {
    _prefetchedAudio = null;
    _prefetchedIndex = -1;
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
    await _audio.stop();
    _playTriggerSubject.add(-1); // Cancels sequence loop via switchMap
  }

  Future<void> skipToNextSentence() async {
    if (_queueIndex + 1 < _queue.length) {
      await _audio.stop();
      _playTriggerSubject.add(_queueIndex + 1);
    } else {
      await stop();
    }
  }

  Future<void> skipToPreviousSentence() async {
    if (_queueIndex > 0) {
      await _audio.stop();
      _playTriggerSubject.add(_queueIndex - 1);
    }
  }

  @disposeMethod
  void dispose() {
    _pipelineSubscription?.cancel();
    _playTriggerSubject.close();
    _stateController.close();
    _chunkController.close();
  }
}
