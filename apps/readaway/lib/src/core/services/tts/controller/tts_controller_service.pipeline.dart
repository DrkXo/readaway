part of 'tts_controller_service.dart';

/// Lookahead synthesis: pre-buffers the first chunks, starts playback, then
/// continues synthesizing and appending the remaining chunks in the background.
extension _TtsSynthesisPipeline on TtsControllerService {
  /// Seconds of silence to bake after [chunk] so the pause before the next
  /// chunk follows the natural-voice curve. The final chunk carries no
  /// trailing pause.
  double _gapForChunk(TtsChunk chunk, int index) {
    if (index >= _masterQueue.length - 1) return 0;
    final base = chunk.isParagraphEnd
        ? kDefaultParagraphGapSec
        : kDefaultSentenceGapSec;
    return bakedGapForRate(base, _rate <= 0 ? 1.0 : _rate);
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
      final isCurrentVoiceValid = _voice != null &&
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

      // 1. Pre-buffer: synthesize up to 2 initial chunks before starting playback
      // to guarantee the player never starves.
      const lookaheadInitialCount = 2;
      final initialEnd = (startIndex + lookaheadInitialCount).clamp(
        startIndex,
        _masterQueue.length,
      );

      final initialSources = <IndexedAudioSource>[];

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
          final result = await engine.synthesizeToBytes(
            text: textToSpeak,
            voice: _voice!,
            speed: 1.0,
            pitch: 1.0,
            gapSec: _gapForChunk(chunk, i),
          );
          consecutiveErrors = 0;
          if (sessionId != _activeSessionId) return;
          _chunkWaveforms[i] = result.waveform;
          if (i == startIndex && !_waveformController.isClosed) {
            _waveformController.add(result.waveform);
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
            duration: Duration(milliseconds: (result.duration * 1000).round()),
          );

          initialSources.add(
            ParagraphStreamAudioSource(
              wavBytes: result.wavBytes,
              duration: Duration(
                milliseconds: (result.duration * 1000).round(),
              ),
              paragraphIndex: i,
              tag: mediaItem,
            ),
          );
        } catch (e) {
          if (sessionId != _activeSessionId) return;
          consecutiveErrors++;
          logger.w(
            'TTS pre-buffering skipped problematic chunk $i ($consecutiveErrors/$maxConsecutiveErrors)',
            e,
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
          final result = await engine.synthesizeToBytes(
            text: textToSpeak,
            voice: _voice!,
            speed: 1.0,
            pitch: 1.0,
            gapSec: _gapForChunk(chunk, i),
          );
          consecutiveErrors = 0;
          if (sessionId != _activeSessionId) return;
          _chunkWaveforms[i] = result.waveform;

          final mediaItem = MediaItem(
            id: '${baseTag?.id ?? 'chunk'}-$i',
            title: chunk.text.length > 50
                ? '${chunk.text.substring(0, 50)}…'
                : chunk.text,
            album: baseTag?.album ?? 'Audiobook',
            artist: baseTag?.artist ?? 'ReadAway',
            genre: baseTag?.genre ?? 'Ebook',
            artUri: baseTag?.artUri,
            duration: Duration(milliseconds: (result.duration * 1000).round()),
          );

          await _audioPlayer.appendSource(
            ParagraphStreamAudioSource(
              wavBytes: result.wavBytes,
              duration: Duration(
                milliseconds: (result.duration * 1000).round(),
              ),
              paragraphIndex: i,
              tag: mediaItem,
            ),
            playIfIdle: true,
          );
        } catch (e) {
          if (sessionId != _activeSessionId) return;
          consecutiveErrors++;
          logger.w(
            'TTS synthesis skipped problematic chunk $i ($consecutiveErrors/$maxConsecutiveErrors)',
            e,
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
      }
    } catch (e, st) {
      if (sessionId != _activeSessionId) return;
      logger.e('TTS playback pipeline crashed', e, st);
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
