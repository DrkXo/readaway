part of 'tts_controller_service.dart';

/// Transport controls: starting the pipeline listeners, playing text,
/// pause/resume/stop, and seeking/skipping between chunks.
extension TtsPlaybackControl on TtsControllerService {
  /// Ensures worker isolate and TTS engine are initialized on-demand.
  Future<void> prepareForPlayback() async {
    await _chunkingService.start();
    final voices = await getInstalledVoices();

    final targetVoiceKey =
        _settingsService.settings.globalViewSettings.ttsVoice;
    TtsVoiceOption? resolvedVoice;

    if (targetVoiceKey != null && targetVoiceKey.isNotEmpty) {
      resolvedVoice = voices
          .where((v) => v.matchesKey(targetVoiceKey))
          .firstOrNull;
    }

    resolvedVoice ??= _voice ?? voices.firstOrNull;

    if (resolvedVoice != null) {
      await setVoice(resolvedVoice);
      final engine = _engineRegistry.getEngineForVoice(resolvedVoice);
      await engine.initialize();
    }
    await _audioPlayer.setSpeed(_rate);
    await _audioPlayer.setPitch(_pitch);
  }

  /// Stops playback, terminates chunker and TTS worker isolates, and cleans temporary files.
  Future<void> releaseResources() async {
    await stopPipeline();
    await _chunkingService.stop();
    await _engineRegistry.disposeAll();
    await _cleanTempFiles();
  }

  /// Initializes stream listeners connecting the audio player to the TTS UI state.
  void start() {
    if (_pipelineStarted) return;
    _pipelineStarted = true;

    // 1. Sync UI state with audio player state
    _playerStateSubscription = _audioPlayer.sessionStateStream.listen((
      playerState,
    ) {
      if (playerState.processingState == ProcessingState.completed) {
        if (_pipelineDone &&
            (_currentIndex == _masterQueue.length - 1 ||
                _currentIndex == -1 ||
                _masterQueue.isEmpty)) {
          // Genuine page-end: all chunks were enqueued and finished playing.
          _currentIndex = -1;
          if (!_chunkController.isClosed) _chunkController.add(null);
          if (!_stateController.isClosed) {
            _stateController.add(
              const TtsPlaybackEvent(TtsPlaybackState.completed),
            );
          }
          _onPageCompletedCallback?.call();
        }
        // If not pipelineDone, player temporarily reached end of buffered items;
        // background synthesis is continuing and will append more.
      } else if (playerState.playing) {
        if (!_stateController.isClosed) {
          _stateController.add(
            const TtsPlaybackEvent(TtsPlaybackState.playing),
          );
        }
      } else if (!playerState.playing &&
          playerState.processingState == ProcessingState.ready) {
        if (!_stateController.isClosed) {
          _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.paused));
        }
      }
    });

    // 2. Track current active chunk as track indices change in the playlist
    _indexSubscription = _audioPlayer.currentIndexStream.listen((trackIndex) {
      if (trackIndex != null && trackIndex >= 0) {
        final masterIndex = _pipelineStartIndex + trackIndex;
        if (masterIndex >= 0 && masterIndex < _masterQueue.length) {
          _currentIndex = masterIndex;
          _lastKnownIndex = masterIndex;
          if (!_chunkController.isClosed) {
            _chunkController.add(_masterQueue[masterIndex]);
          }
          if (!_waveformController.isClosed) {
            _waveformController.add(_chunkWaveforms[masterIndex] ?? const []);
          }
        }
      }
    });
  }

  /// Halts any active playback, cancels subscriptions, cleans up temp files,
  /// and tears down chunking isolate.
  Future<void> stopPipeline() async {
    _activeSessionId++;
    _onPageCompletedCallback = null;
    await _audioPlayer.stopSession();
    await _indexSubscription?.cancel();
    _indexSubscription = null;
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _pipelineStarted = false;
    _resetPlaybackState();
    await _cleanTempFiles();
    await _chunkingService.stop();
  }

  /// Synthesizes text with lookahead pre-buffering into native WAV files
  /// and feeds them gaplessly into [AudioPlayerService].
  Future<void> playText(
    String text, {
    int startAtChunkIndex = 0,
    void Function()? onPlaybackStarted,
    void Function()? onComplete,
    MediaItem? tag,
    int? pageIndex,
  }) => _pipelineMutex.protect(() async {
    _currentPageIndex = pageIndex;
    _onPageCompletedCallback = onComplete;
    if (!_pageIndexController.isClosed) {
      _pageIndexController.add(pageIndex);
    }

    if (_voice == null) {
      if (!_stateController.isClosed) {
        _stateController.add(
          const TtsPlaybackEvent(
            TtsPlaybackState.error,
            message: 'No voice selected. Call setVoice() first.',
          ),
        );
      }
      return;
    }

    final sessionId = ++_activeSessionId;
    if (!_stateController.isClosed) {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.loading));
    }
    await _audioPlayer.stopSession();
    await _cleanTempFiles();

    // Chunk text in background isolate
    final List<TtsChunk> chunks;
    try {
      chunks = await _chunkingService.chunkText(text);
    } catch (e, st) {
      logger.e('Failed to chunk text for TTS', e, st);
      if (!_stateController.isClosed) {
        _stateController.add(
          TtsPlaybackEvent(
            TtsPlaybackState.error,
            message: 'Failed to tokenize text: $e',
          ),
        );
      }
      return;
    }

    if (sessionId != _activeSessionId) return;

    _masterQueue = chunks;
    _baseTag = tag;
    _currentIndex = -1;
    final startIndex = startAtChunkIndex.clamp(0, _masterQueue.length - 1);
    _lastKnownIndex = startIndex;
    _pipelineStartIndex = startIndex;
    _chunkWaveforms.clear();
    if (!_waveformController.isClosed) _waveformController.add(const []);
    if (!_chunkController.isClosed && startIndex < _masterQueue.length) {
      _chunkController.add(_masterQueue[startIndex]);
    }
    if (!_queueController.isClosed) {
      _queueController.add(_queueController.value + 1);
    }

    if (_masterQueue.isEmpty) {
      _resetPlaybackState();
      return;
    }

    _pipelineDone = false;

    StreamSubscription<TtsPlaybackEvent>? startSub;
    if (onPlaybackStarted != null) {
      startSub = _stateController.stream.listen((event) {
        if (event.state == TtsPlaybackState.playing ||
            event.state == TtsPlaybackState.error) {
          if (event.state == TtsPlaybackState.playing) onPlaybackStarted();
          startSub?.cancel();
        }
      });
    }

    // Run lookahead synthesis pipeline
    unawaited(_synthesizeAndPlayPipeline(sessionId, startIndex, tag));
  });

  Future<void> pause() => _audioPlayer.pause();

  Future<void> resume() async {
    final isStoppedOrCompleted =
        _stateController.value.state == TtsPlaybackState.stopped ||
        _stateController.value.state == TtsPlaybackState.completed;

    if (_audioPlayer.playlistLength > 0 && !isStoppedOrCompleted) {
      await _audioPlayer.resume();
    } else if (_masterQueue.isNotEmpty) {
      final startIndex =
          (_lastKnownIndex >= 0 && _lastKnownIndex < _masterQueue.length)
          ? _lastKnownIndex
          : 0;
      final sessionId = ++_activeSessionId;
      await _audioPlayer.stopSession();
      await _cleanTempFiles();
      _pipelineDone = false;
      unawaited(_synthesizeAndPlayPipeline(sessionId, startIndex, _baseTag));
    }
  }

  Future<void> stop() async {
    _activeSessionId++;
    await _audioPlayer.stopSession();
    await _cleanTempFiles();
    _resetPlaybackState();
  }

  Future<void> skipToNextSentence() async {
    final cur = _currentIndex >= 0 ? _currentIndex : _lastKnownIndex;
    if (cur + 1 < _masterQueue.length) {
      await seekToChunk(cur + 1);
    } else {
      await stop();
    }
  }

  Future<void> skipToPreviousSentence() async {
    final cur = _currentIndex >= 0 ? _currentIndex : _lastKnownIndex;
    if (cur > 0) {
      await seekToChunk(cur - 1);
    }
  }

  Future<void> seekToChunk(int index) async {
    if (index < 0 || index >= _masterQueue.length) return;
    try {
      final playlistIndex = index - _pipelineStartIndex;
      final isStoppedOrCompleted =
          _stateController.value.state == TtsPlaybackState.stopped ||
          _stateController.value.state == TtsPlaybackState.completed;

      if (!isStoppedOrCompleted &&
          playlistIndex >= 0 &&
          playlistIndex < _audioPlayer.playlistLength) {
        await _audioPlayer.seekToIndex(playlistIndex);
      } else {
        // Requested sentence has not been synthesized into active playlist yet,
        // or player was stopped. Re-route synthesis pipeline from this chunk forward!
        final sessionId = ++_activeSessionId;
        await _audioPlayer.stopSession();
        await _cleanTempFiles();
        _pipelineDone = false;
        unawaited(_synthesizeAndPlayPipeline(sessionId, index, _baseTag));
      }
    } catch (e, st) {
      logger.e('Failed to seek to sentence $index', e, st);
    }
  }

  /// Seeks to a position within the currently playing sentence track.
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
}
