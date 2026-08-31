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
  final Queue<TtsChunk> _pendingQueue = Queue<TtsChunk>();
  int _currentIndex = -1;

  int _playGeneration = 0;

  final _generationSubject = BehaviorSubject<int>.seeded(0);

  int _bumpGeneration() {
    _playGeneration++;
    _generationSubject.add(_playGeneration);
    return _playGeneration;
  }

  static const int _maxPrefetchDepth = 2;
  final Map<int, TtsAudio> _audioCache = {};
  final Set<int> _synthesizingIndices = {};

  final _commandSubject = PublishSubject<_PlaybackCommand>();
  final _stateController = BehaviorSubject<TtsPlaybackEvent>.seeded(
    const TtsPlaybackEvent(TtsPlaybackState.stopped),
  );
  final _chunkController = BehaviorSubject<TtsChunk?>();

  StreamSubscription<void>? _pipelineSubscription;

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
    _pipelineSubscription = _commandSubject
        .switchMap((command) => _executeCommandStream(command))
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

  Stream<void> _executeCommandStream(_PlaybackCommand command) async* {
    if (command.type == _CommandType.stop) {
      await _audio.stop();
      _resetPlaybackState();
      return;
    }

    if (command.type == _CommandType.playIndex) {
      final generation = command.generation;

      await _audio.stop();

      if (generation != _playGeneration) return;

      _setupQueueFromIndex(command.index);

      while (_pendingQueue.isNotEmpty) {
        if (generation != _playGeneration) return;

        final currentChunk = _pendingQueue.removeFirst();
        _currentIndex = _masterQueue.indexOf(currentChunk);

        _chunkController.add(currentChunk);
        _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));

        unawaited(_triggerPrefetchPipeline(generation));

        try {
          final audio = await _getOrGenerateAudio(_currentIndex, currentChunk);

          if (generation != _playGeneration) return;

          await _audio.playPcm(audio);

          final supersededOrCompleted = await Future.any([
            _audio.playerState
                .firstWhere(
                  (state) => state.processingState == ProcessingState.completed,
                )
                .then((_) => true),
            _generationSubject.stream
                .firstWhere((g) => g != generation)
                .then((_) => false),
          ]);

          if (!supersededOrCompleted || generation != _playGeneration) {
            return;
          }

          _audioCache.remove(_currentIndex);
        } catch (e) {
          if (generation != _playGeneration) return;
          if (_stateController.value.state == TtsPlaybackState.stopped) return;
          _stateController.add(
            TtsPlaybackEvent(TtsPlaybackState.error, message: e.toString()),
          );
          return;
        }
      }

      if (generation == _playGeneration) {
        _resetPlaybackState();
      }
    }
  }

  Future<TtsAudio> _getOrGenerateAudio(int index, TtsChunk chunk) async {
    if (_audioCache.containsKey(index)) {
      return _audioCache.remove(index)!;
    }

    return await _sherpaTts.generate(
      text: chunk.text,
      speakerId: _voice?.sherpaSpeakerId ?? 0,
      speed: _rate <= 0 ? 1.0 : _rate,
    );
  }

  Future<void> _triggerPrefetchPipeline(int generation) async {
    final nextChunks = _pendingQueue.take(_maxPrefetchDepth).toList();

    for (final chunk in nextChunks) {
      if (generation != _playGeneration) return;

      final index = _masterQueue.indexOf(chunk);

      if (_audioCache.containsKey(index) ||
          _synthesizingIndices.contains(index)) {
        continue;
      }

      _synthesizingIndices.add(index);

      try {
        final audio = await _sherpaTts.generate(
          text: chunk.text,
          speakerId: _voice?.sherpaSpeakerId ?? 0,
          speed: _rate <= 0 ? 1.0 : _rate,
        );
        if (generation == _playGeneration) {
          _audioCache[index] = audio;
        }
      } catch (e) {
        logger.d('TTS prefetch failed for chunk $index', e);
      } finally {
        _synthesizingIndices.remove(index);
      }
    }
  }

  void _clearPrefetchCache() {
    _audioCache.clear();
    _synthesizingIndices.clear();
  }

  void _resetPlaybackState() {
    _currentIndex = -1;
    _pendingQueue.clear();
    _clearPrefetchCache();
    _chunkController.add(null);
    _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
  }

  void _setupQueueFromIndex(int index) {
    _pendingQueue.clear();
    if (index >= 0 && index < _masterQueue.length) {
      _pendingQueue.addAll(_masterQueue.sublist(index));
    }
  }

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

    final myGeneration = _bumpGeneration();

    final chunks = await _chunkingService.chunkText(text);

    if (myGeneration != _playGeneration) return;

    _masterQueue = chunks;
    _clearPrefetchCache();

    _commandSubject.add(
      _PlaybackCommand.play(startAtChunkIndex, generation: myGeneration),
    );
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
    _bumpGeneration();
    await _audio.stop();
    _commandSubject.add(_PlaybackCommand.stop());
  }

  Future<void> skipToNextSentence() async {
    if (_currentIndex + 1 < _masterQueue.length) {
      _commandSubject.add(
        _PlaybackCommand.play(_currentIndex + 1, generation: _playGeneration),
      );
    } else {
      await stop();
    }
  }

  Future<void> skipToPreviousSentence() async {
    if (_currentIndex > 0) {
      _commandSubject.add(
        _PlaybackCommand.play(_currentIndex - 1, generation: _playGeneration),
      );
    }
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

  Stream<ModelDownloadProgress> downloadSherpaVoice(
    SherpaTtsModelInfo model,
  ) => _sherpaTts.downloadModel(model);

  Future<void> deleteSherpaVoice(String modelId) =>
      _sherpaTts.deleteModel(modelId);

  Future<void> setVoice(TtsVoiceOption voice) async {
    if (_voice?.id == voice.id) return;
    _voice = voice;
    _clearPrefetchCache();

    if (_sherpaTts.activeModel?.id != voice.id) {
      await _sherpaTts.loadModel(voice.id);
    }
  }

  Future<void> setRate(double rate) async {
    if (_rate == rate) return;
    _rate = rate;
    _clearPrefetchCache();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
  }

  @disposeMethod
  void dispose() {
    _pipelineSubscription?.cancel();
    _commandSubject.close();
    _stateController.close();
    _chunkController.close();
    _generationSubject.close();
  }
}

enum _CommandType { playIndex, stop }

class _PlaybackCommand {
  const _PlaybackCommand._(this.type, this.index, this.generation);

  factory _PlaybackCommand.play(int index, {required int generation}) =>
      _PlaybackCommand._(_CommandType.playIndex, index, generation);

  factory _PlaybackCommand.stop() =>
      const _PlaybackCommand._(_CommandType.stop, -1, -1);

  final _CommandType type;
  final int index;
  final int generation;
}
