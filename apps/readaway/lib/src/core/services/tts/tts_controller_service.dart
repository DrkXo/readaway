part of '../services.dart';

@lazySingleton
class TtsControllerService {
  TtsControllerService(
    this._sherpaTts,
    this._audio,
    this._chunkingService,
  );

  final SherpaOnnxTtsService _sherpaTts;
  final JustAudioService _audio;
  final TtsChunkingService _chunkingService;

  TtsVoiceOption? _voice;
  double _rate = 1.0;

  // ignore: unused_field
  double _pitch = 1.0;

  List<TtsChunk> _masterQueue = [];
  int _currentIndex = -1;

  // Track active synthesis jobs so stale tasks can cancel gracefully
  int _activeSessionId = 0;

  final _stateController = BehaviorSubject<TtsPlaybackEvent>.seeded(
    const TtsPlaybackEvent(TtsPlaybackState.idle),
  );
  final _chunkController = BehaviorSubject<TtsChunk?>();

  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  ValueStream<TtsPlaybackEvent> get playbackState => _stateController.stream;

  Stream<TtsChunk> get currentChunk => _chunkController.stream.whereNotNull();

  List<TtsChunk> get queue => List.unmodifiable(_masterQueue);

  int get queueLength => _masterQueue.length;

  int? get currentChunkIndex => _currentIndex >= 0 ? _currentIndex : null;

  TtsVoiceOption? get currentVoice => _voice;

  List<SherpaTtsModelInfo> get availableSherpaModels =>
      _sherpaTts.availableModels;

  @PostConstruct()
  void initPipeline() {
    // 1. Sync UI state with native audio player state
    _playerStateSubscription = _audio.sessionStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _resetPlaybackState();
      } else if (playerState.playing) {
        _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));
      } else if (!playerState.playing &&
          playerState.processingState == ProcessingState.ready) {
        _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.paused));
      }
    });

    // 2. Track current active chunk natively as track indices change
    _indexSubscription = _audio.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _masterQueue.length) {
        _currentIndex = index;
        _chunkController.add(_masterQueue[index]);
      }
    });
  }

  /// Synthesizes text into chunks and streams them into the audio queue gaplessly.
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

    // Increment session marker to cancel active background synthesis loops
    final sessionId = ++_activeSessionId;

    // Reset current active player queue
    await _audio.stopSession();

    final chunks = await _chunkingService.chunkText(text);

    if (sessionId != _activeSessionId) return;

    _masterQueue = chunks;

    if (_masterQueue.isEmpty) {
      _resetPlaybackState();
      return;
    }

    final startIndex = startAtChunkIndex.clamp(0, _masterQueue.length - 1);

    // Start playback streaming pipeline asynchronously
    unawaited(_synthesizeAndEnqueuePipeline(sessionId, startIndex));
  }

  /// Background pipeline that generates PCM frames and pushes them into JustAudioService
  Future<void> _synthesizeAndEnqueuePipeline(
    int sessionId,
    int startIndex,
  ) async {
    for (var i = startIndex; i < _masterQueue.length; i++) {
      if (sessionId != _activeSessionId) return;

      final chunk = _masterQueue[i];

      try {
        final audio = await _sherpaTts.generate(
          text: chunk.text,
          speakerId: _voice?.sherpaSpeakerId ?? 0,
          speed: _rate <= 0 ? 1.0 : _rate,
        );

        if (sessionId != _activeSessionId) return;

        // Dynamic enqueue into JustAudioService dynamic playlist queue
        await _audio.enqueueChunk(audio);
      } catch (e) {
        if (sessionId != _activeSessionId) return;
        logger.d('TTS synthesis failed for chunk index $i', e);
        _stateController.add(
          TtsPlaybackEvent(TtsPlaybackState.error, message: e.toString()),
        );
        return;
      }
    }
  }

  Future<void> pause() async {
    await _audio.pause();
  }

  Future<void> resume() async {
    await _audio.resume();
  }

  Future<void> stop() async {
    _activeSessionId++;
    await _audio.stopSession();
    _resetPlaybackState();
  }

  Future<void> skipToNextSentence() async {
    if (_currentIndex + 1 < _masterQueue.length) {
      await _audio.seekToChunk(_currentIndex + 1);
    } else {
      await stop();
    }
  }

  Future<void> skipToPreviousSentence() async {
    if (_currentIndex > 0) {
      await _audio.seekToChunk(_currentIndex - 1);
    }
  }

  void _resetPlaybackState() {
    _currentIndex = -1;
    _chunkController.add(null);
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
  }

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
        .toList(growable: false);
  }

  Future<void> setRate(double rate) async {
    if (_rate == rate) return;
    _rate = rate;
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
  }

  @disposeMethod
  void dispose() {
    _indexSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _stateController.close();
    _chunkController.close();
  }
}
