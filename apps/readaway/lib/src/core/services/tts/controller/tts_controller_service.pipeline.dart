part of 'tts_controller_service.dart';

/// Lookahead synthesis: pre-buffers the first chunks, starts playback, then
/// continues synthesizing and appending the remaining chunks in the background.
extension _TtsSynthesisPipeline on TtsControllerService {
  /// Seconds of silence to bake after [chunk] so the pause before the next
  /// chunk follows the natural-voice curve. The final chunk carries no
  /// trailing pause.
  double _gapForChunk(TtsChunk chunk, int index) {
    if (index >= _masterQueue.length - 1) return 0.0;
    final gvs = _settingsService.settings.globalViewSettings;
    return computeChunkGapSec(
      chunk,
      sentenceGapMs: gvs.ttsSentenceGap,
      paragraphGapMs: gvs.ttsParagraphGap,
      rate: _rate <= 0 ? 1.0 : _rate,
      isLastChunk: index >= _masterQueue.length - 1,
    );
  }

  /// Lookahead synthesis pipeline: pre-synthesizes initial buffer, starts playback,
  /// and continues queuing remaining chunks ahead of playback.
  Future<void> _synthesizeAndPlayPipeline(
    int sessionId,
    int startIndex,
    MediaItem? baseTag, {
    bool autoPlay = true,
  }) async {
    _pipelineStartIndex = startIndex;
    _currentIndex = startIndex;
    _lastKnownIndex = startIndex;
    if (!_chunkController.isClosed && startIndex < _masterQueue.length) {
      _chunkController.add(_masterQueue[startIndex]);
    }
    if (!_stateController.isClosed && autoPlay) {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.loading));
    }
    try {
      final voices = await getInstalledVoices();
      final isCurrentVoiceValid =
          _voice != null &&
          voices.any(
            (v) =>
                v.id == _voice!.id &&
                v.sherpaSpeakerId == _voice!.sherpaSpeakerId,
          );

      if (!isCurrentVoiceValid) {
        final targetVoiceKey =
            _settingsService.settings.globalViewSettings.ttsVoice;
        TtsVoiceOption? resolvedVoice;
        if (targetVoiceKey != null && targetVoiceKey.isNotEmpty) {
          resolvedVoice = voices
              .where((v) => v.matchesKey(targetVoiceKey))
              .firstOrNull;
        }
        resolvedVoice ??= voices.firstOrNull;

        if (resolvedVoice != null) {
          await setVoice(resolvedVoice);
        } else {
          _voice = null;
          if (!_voiceController.isClosed) {
            _voiceController.add(null);
          }
          throw const SherpaTtsException(
            'No TTS voice available. Download a voice first.',
          );
        }
      }

      final engine = _engineRegistry.getEngineForVoice(_voice!);
      await engine.initialize();

      final bookPath = _currentBookPath ?? 'doc';
      final chapterIndex = _currentSectionIndex ?? _currentPageIndex ?? 0;
      final fullSpeechText = _masterQueue.map((c) => c.speechContent).join('\n');
      final textHash = _cacheService.computeTextHash(fullSpeechText);

      // Try loading existing chapter manifest or initialize new one
      _currentChapterManifest = await _cacheService.getChapterManifest(
        bookPath: bookPath,
        chapterIndex: chapterIndex,
        voice: _voice!,
        textHash: textHash,
      );

      _currentChapterManifest ??= TtsChapterCacheManifest(
        chapterIndex: chapterIndex,
        textHash: textHash,
        voiceId: _voice!.id,
        speakerId: _voice!.sherpaSpeakerId ?? 0,
        configHash: _cacheService.computeConfigHash(
          _settingsService.settings.globalViewSettings,
        ),
        sampleRate: engine is SherpaOnnxTtsEngine ? 22050 : 22050,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );

      // 1. Pre-buffer: load from cache or synthesize up to 2 initial chunks
      // before starting playback to guarantee the player never starves.
      const lookaheadInitialCount = 2;
      final initialEnd = (startIndex + lookaheadInitialCount).clamp(
        startIndex,
        _masterQueue.length,
      );

      final initialSources = <AudioSource>[];

      var consecutiveErrors = 0;
      const maxConsecutiveErrors = 3;

      for (var i = startIndex; i < initialEnd; i++) {
        if (sessionId != _activeSessionId) return;
        final chunk = _masterQueue[i];
        final textToSpeak = chunk.speechContent;
        if (textToSpeak.trim().isEmpty) {
          consecutiveErrors = 0;
          continue;
        }

        try {
          final chunkFile = await _cacheService.getChunkFile(
            bookPath: bookPath,
            chapterIndex: chapterIndex,
            voice: _voice!,
            chunkIndex: i,
          );
          final isCached = await _cacheService.isChunkFileValid(chunkFile);

          List<double> waveform;
          Duration duration;

          if (isCached) {
            final cachedMeta = _currentChapterManifest?.getChunk(i);
            waveform = cachedMeta?.waveform ?? const [];
            final durationSec = cachedMeta?.durationSec ?? 0.0;
            duration = durationSec > 0
                ? Duration(milliseconds: (durationSec * 1000).round())
                : Duration(milliseconds: chunk.estimatedDurationMs);
          } else {
            final result = await engine.synthesizeToFile(
              text: textToSpeak,
              outputPath: chunkFile.path,
              voice: _voice!,
              speed: 1.0,
              pitch: 1.0,
              gapSec: _gapForChunk(chunk, i),
            );
            waveform = result.waveform;
            duration = Duration(milliseconds: (result.duration * 1000).round());

            final cachedChunk = TtsCachedChunk(
              chunkIndex: i,
              fileName: p.basename(chunkFile.path),
              startOffset: chunk.startOffset,
              endOffset: chunk.endOffset,
              durationSec: result.duration,
              waveform: result.waveform,
              gapSec: _gapForChunk(chunk, i),
            );
            _currentChapterManifest =
                _currentChapterManifest?.withChunk(cachedChunk);
            if (_currentChapterManifest != null) {
              await _cacheService.saveChapterManifest(
                bookPath: bookPath,
                chapterIndex: chapterIndex,
                voice: _voice!,
                manifest: _currentChapterManifest!,
              );
            }
          }

          consecutiveErrors = 0;
          if (sessionId != _activeSessionId) return;
          _chunkWaveforms[i] = waveform;
          if (i == startIndex && !_waveformController.isClosed) {
            _waveformController.add(waveform);
          }

          final mediaItem = MediaItem(
            id: '${baseTag?.id ?? 'chunk'}-$i',
            title: chunk.text.length > 50
                ? '${chunk.text.substring(0, 50)}…'
                : chunk.text,
            album: baseTag?.album ?? 'Audiobook',
            artist: baseTag?.artist ?? 'ReadAway',
            genre: baseTag?.genre ?? 'Ebook',
            artUri: baseTag?.artUri,
            duration: duration,
          );

          initialSources.add(
            AudioSource.file(
              chunkFile.path,
              tag: mediaItem,
            ),
          );
        } catch (e, st) {
          if (sessionId != _activeSessionId) return;
          consecutiveErrors++;
          _log.w(
            'TTS pre-buffering skipped problematic chunk $i ($consecutiveErrors/$maxConsecutiveErrors)',
            error: e,
            stackTrace: st,
          );
          if (consecutiveErrors >= maxConsecutiveErrors) {
            _stateController.add(
              TtsPlaybackEvent(TtsPlaybackState.error, message: e.toString()),
            );
            return;
          }
        }
      }

      if (sessionId != _activeSessionId) return;

      if (initialSources.isEmpty && initialEnd < _masterQueue.length) {
        // In case initial chunks were skipped, proceed to synthesize further
      } else if (initialSources.isNotEmpty) {
        // Start playlist playback with the pre-buffered items
        await _audioPlayer.setPlaylist(
          initialSources,
          initialIndex: 0,
          autoPlay: autoPlay,
        );
      }

      if (initialEnd >= _masterQueue.length) {
        // Entire text was small enough to fit into initial buffer
        _pipelineDone = true;
        if (_currentChapterManifest != null) {
          _currentChapterManifest =
              _currentChapterManifest!.copyWith(isComplete: true);
          await _cacheService.saveChapterManifest(
            bookPath: bookPath,
            chapterIndex: chapterIndex,
            voice: _voice!,
            manifest: _currentChapterManifest!,
          );
        }
        unawaited(_cacheService.enforceCacheLimit());
        return;
      }

      // 2. Continue background synthesis for the rest of the chunks
      for (var i = initialEnd; i < _masterQueue.length; i++) {
        if (sessionId != _activeSessionId) return;
        final chunk = _masterQueue[i];
        final textToSpeak = chunk.speechContent;
        if (textToSpeak.trim().isEmpty) {
          consecutiveErrors = 0;
          continue;
        }

        try {
          final chunkFile = await _cacheService.getChunkFile(
            bookPath: bookPath,
            chapterIndex: chapterIndex,
            voice: _voice!,
            chunkIndex: i,
          );
          final isCached = await _cacheService.isChunkFileValid(chunkFile);

          List<double> waveform;
          Duration duration;

          if (isCached) {
            final cachedMeta = _currentChapterManifest?.getChunk(i);
            waveform = cachedMeta?.waveform ?? const [];
            final durationSec = cachedMeta?.durationSec ?? 0.0;
            duration = durationSec > 0
                ? Duration(milliseconds: (durationSec * 1000).round())
                : Duration(milliseconds: chunk.estimatedDurationMs);
          } else {
            final result = await engine.synthesizeToFile(
              text: textToSpeak,
              outputPath: chunkFile.path,
              voice: _voice!,
              speed: 1.0,
              pitch: 1.0,
              gapSec: _gapForChunk(chunk, i),
            );
            waveform = result.waveform;
            duration = Duration(milliseconds: (result.duration * 1000).round());

            final cachedChunk = TtsCachedChunk(
              chunkIndex: i,
              fileName: p.basename(chunkFile.path),
              startOffset: chunk.startOffset,
              endOffset: chunk.endOffset,
              durationSec: result.duration,
              waveform: result.waveform,
              gapSec: _gapForChunk(chunk, i),
            );
            _currentChapterManifest =
                _currentChapterManifest?.withChunk(cachedChunk);
            if (_currentChapterManifest != null) {
              await _cacheService.saveChapterManifest(
                bookPath: bookPath,
                chapterIndex: chapterIndex,
                voice: _voice!,
                manifest: _currentChapterManifest!,
              );
            }
          }

          consecutiveErrors = 0;
          if (sessionId != _activeSessionId) return;
          _chunkWaveforms[i] = waveform;

          final mediaItem = MediaItem(
            id: '${baseTag?.id ?? 'chunk'}-$i',
            title: chunk.text.length > 50
                ? '${chunk.text.substring(0, 50)}…'
                : chunk.text,
            album: baseTag?.album ?? 'Audiobook',
            artist: baseTag?.artist ?? 'ReadAway',
            genre: baseTag?.genre ?? 'Ebook',
            artUri: baseTag?.artUri,
            duration: duration,
          );

          await _audioPlayer.appendSource(
            AudioSource.file(
              chunkFile.path,
              tag: mediaItem,
            ),
            playIfIdle: true,
          );
        } catch (e, st) {
          if (sessionId != _activeSessionId) return;
          consecutiveErrors++;
          _log.w(
            'TTS synthesis skipped problematic chunk $i ($consecutiveErrors/$maxConsecutiveErrors)',
            error: e,
            stackTrace: st,
          );
          if (consecutiveErrors >= maxConsecutiveErrors) {
            _stateController.add(
              TtsPlaybackEvent(TtsPlaybackState.error, message: e.toString()),
            );
            return;
          }
        }
      }

      if (sessionId == _activeSessionId) {
        _pipelineDone = true;
        if (_currentChapterManifest != null) {
          _currentChapterManifest =
              _currentChapterManifest!.copyWith(isComplete: true);
          await _cacheService.saveChapterManifest(
            bookPath: bookPath,
            chapterIndex: chapterIndex,
            voice: _voice!,
            manifest: _currentChapterManifest!,
          );
        }
        unawaited(_cacheService.enforceCacheLimit());
      }
    } catch (e, st) {
      if (sessionId != _activeSessionId) return;
      _log.e('TTS playback pipeline crashed', error: e, stackTrace: st);
      if (!_stateController.isClosed) {
        _stateController.add(
          TtsPlaybackEvent(
            TtsPlaybackState.error,
            message: 'Playback pipeline failure: $e',
          ),
        );
      }
    }
  }
}
