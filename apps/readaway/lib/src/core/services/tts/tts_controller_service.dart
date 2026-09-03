part of '../services.dart';

/// Manages TTS playback pipeline: chunking, synthesis, and gapless audio
/// enqueue. Scoped to the ReaderBloc lifecycle — [start] is called on bloc
/// construction and [stopPipeline] is called on [ReaderBloc.close]. The
/// terminal [dispose] is reserved for app-shutdown via GetIt.
@lazySingleton
class TtsControllerService {
  TtsControllerService(
    this._sherpaTts,
    this._justAudio,
    this._chunkingService,
  );

  final SherpaOnnxTtsService _sherpaTts;
  final JustAudioService _justAudio;
  final TtsChunkingService _chunkingService;

  TtsVoiceOption? _voice;
  double _rate = 1.0;

  final _voiceController = BehaviorSubject<TtsVoiceOption?>.seeded(null);

  ValueStream<TtsVoiceOption?> get currentVoiceOption =>
      _voiceController.stream;

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

  /// Bumped whenever [_masterQueue] is (re)built so UI can rebuild its
  /// sentence list even before the first chunk starts playing.
  final _queueController = BehaviorSubject<int>.seeded(0);

  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _pipelineStarted = false;

  /// True once the synthesis pipeline has enqueued every chunk of the current
  /// page. Lets the player-state listener distinguish a genuine page-end
  /// ([TtsPlaybackState.completed]) from a transient queue completion that
  /// happens while synthesis is still enqueuing (which
  /// [JustAudioService.enqueueChunk] auto-resumes).
  bool _pipelineDone = false;

  ValueStream<TtsPlaybackEvent> get playbackState => _stateController.stream;

  Stream<TtsChunk> get currentChunk => _chunkController.stream.whereNotNull();

  /// Emits a new value each time the sentence queue is rebuilt.
  ValueStream<int> get queueVersion => _queueController.stream;

  List<TtsChunk> get queue => List.unmodifiable(_masterQueue);

  int get queueLength => _masterQueue.length;

  int? get currentChunkIndex => _currentIndex >= 0 ? _currentIndex : null;

  TtsVoiceOption? get currentVoice => _voice;

  List<SherpaTtsModelInfo> get availableSherpaModels =>
      _sherpaTts.availableModels;

  /// Sets up stream subscriptions that sync UI state with the native audio
  /// player. Idempotent — safe to call multiple times across reader open/close
  /// cycles (the [start] check + [stopPipeline] reset make it re-entrant).
  void start() {
    logger.d('Starting TTS pipeline');
    if (_pipelineStarted) return;

    _pipelineStarted = true;

    // 1. Sync UI state with native audio player state
    _playerStateSubscription = _justAudio.sessionStateStream.listen((
      playerState,
    ) {
      if (playerState.processingState == ProcessingState.completed) {
        if (_pipelineDone) {
          // Genuine page-end: every chunk was enqueued and the queue finished.
          _currentIndex = -1;
          _chunkController.add(null);
          _stateController.add(
            const TtsPlaybackEvent(TtsPlaybackState.completed),
          );
        }
        // Otherwise this is a transient completion while synthesis is still
        // enqueuing; JustAudioService.enqueueChunk auto-resumes playback.
      } else if (playerState.playing) {
        _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));
      } else if (!playerState.playing &&
          playerState.processingState == ProcessingState.ready) {
        _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.paused));
      }
    });
    logger.d('TTS pipeline started');
    logger.d('TTS pipeline listeners starting');
    // 2. Track current active chunk natively as track indices change
    _indexSubscription = _justAudio.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _masterQueue.length) {
        _currentIndex = index;
        _chunkController.add(_masterQueue[index]);
      }
    });
    logger.d('TTS pipeline listeners started');
  }

  /// Tears down active subscriptions, halts any in-flight playback, and kills
  /// the chunking isolate. Non-terminal — the [BehaviorSubject] controllers
  /// remain open so the singleton can be re-started by a subsequent
  /// [start] call. Called by [ReaderBloc.close]; the terminal [dispose] is
  /// reserved for app shutdown via GetIt.
  Future<void> stopPipeline() async {
    logger.d('Stopping TTS pipeline');
    _activeSessionId++;
    await _justAudio.stopSession();
    _indexSubscription?.cancel();
    _indexSubscription = null;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _pipelineStarted = false;
    _resetPlaybackState();
    await _chunkingService.stop();
    logger.d('TTS pipeline stopped');
  }

  /// Synthesizes text into chunks and streams them into the audio queue gaplessly.
  Future<void> playText(
    String text, {
    int startAtChunkIndex = 0,
    void Function()? onPlaybackStarted,
    MediaItem? tag,
  }) async {
    if (_voice == null) {
      _stateController.add(
        const TtsPlaybackEvent(
          TtsPlaybackState.error,
          message: 'No voice selected. Call setVoice() first.',
        ),
      );
      return;
    }

    final sessionId = ++_activeSessionId;
    await _justAudio.stopSession();

    final chunks = await _chunkingService.chunkText(text);
    if (sessionId != _activeSessionId) return;

    _masterQueue = chunks;
    _currentIndex = -1;
    _chunkController.add(null);
    _queueController.add(_queueController.value + 1);

    if (_masterQueue.isEmpty) {
      _resetPlaybackState();
      return;
    }

    final startIndex = startAtChunkIndex.clamp(0, _masterQueue.length - 1);
    _pipelineDone = false;

    StreamSubscription<TtsPlaybackEvent>? startSub;
    if (onPlaybackStarted != null) {
      startSub = _stateController.stream.listen((event) {
        if (event.state == TtsPlaybackState.playing ||
            event.state == TtsPlaybackState.error) {
          // fire (or bail) once, then stop listening either way
          if (event.state == TtsPlaybackState.playing) onPlaybackStarted();
          startSub?.cancel();
        }
      });
    }

    unawaited(_synthesizeAndEnqueuePipeline(sessionId, startIndex, tag));
  }

  /// Background pipeline that generates PCM frames and pushes them into JustAudioService
  Future<void> _synthesizeAndEnqueuePipeline(
    int sessionId,
    int startIndex, [
    MediaItem? tag,
  ]) async {
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
        await _justAudio.enqueueChunk(audio, tag);
      } catch (e) {
        if (sessionId != _activeSessionId) return;
        logger.d('TTS synthesis failed for chunk index $i', e);
        _stateController.add(
          TtsPlaybackEvent(TtsPlaybackState.error, message: e.toString()),
        );
        return;
      }
    }

    // Every chunk of the current page has been enqueued. Mark the queue as
    // finalized so the next ProcessingState.completed is treated as a genuine
    // page-end rather than a transient completion.
    if (sessionId == _activeSessionId) {
      _pipelineDone = true;
    }
  }

  Future<void> pause() async {
    await _justAudio.pause();
  }

  Future<void> resume() async {
    await _justAudio.resume();
  }

  Future<void> stop() async {
    _activeSessionId++;
    await _justAudio.stopSession();
    _resetPlaybackState();
  }

  Future<void> skipToNextSentence() async {
    if (_currentIndex + 1 < _masterQueue.length) {
      await _justAudio.seekToChunk(_currentIndex + 1);
    } else {
      await stop();
    }
  }

  Future<void> skipToPreviousSentence() async {
    if (_currentIndex > 0) {
      await _justAudio.seekToChunk(_currentIndex - 1);
    }
  }

  /// Seeks playback to the sentence at [index] in the current queue.
  Future<void> seekToChunk(int index) async {
    if (index < 0 || index >= _masterQueue.length) return;
    await _justAudio.seekToChunk(index);
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
            sherpaSpeakerId: m.speakerCount > 0 ? 0 : null,
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

  Future<void> setVoice(TtsVoiceOption voice) async {
    _voice = voice;
    _voiceController.add(voice);
  }

  @disposeMethod
  Future<void> dispose() async {
    await stopPipeline();
    _stateController.close();
    _chunkController.close();
    _queueController.close();
    _voiceController.close();
  }
}
