part of 'tts_controller_service.dart';

/// Voice selection, rate/pitch control, and external-settings synchronization.
extension TtsVoiceAndRate on TtsControllerService {
  void _onSettingsChanged(Settings settings) {
    final gvs = settings.globalViewSettings;

    // Sync rate if changed externally
    if (gvs.ttsRate > 0 && (gvs.ttsRate - _rate).abs() >= 0.001) {
      _rate = gvs.ttsRate;
      if (!_rateController.isClosed) {
        _rateController.add(_rate);
      }
      unawaited(_audioPlayer.setSpeed(_rate));
    }

    // Sync pitch if changed externally
    if (gvs.ttsPitch > 0 && (gvs.ttsPitch - _pitch).abs() >= 0.001) {
      _pitch = gvs.ttsPitch;
      if (!_pitchController.isClosed) {
        _pitchController.add(_pitch);
      }
      unawaited(_audioPlayer.setPitch(_pitch));
    }

    final targetVoiceKey = gvs.ttsVoice;
    if (targetVoiceKey == null || targetVoiceKey.isEmpty) {
      if (_voice != null) {
        _voice = null;
        if (!_voiceController.isClosed) {
          _voiceController.add(null);
        }
      }
      return;
    }
    if (_voice?.matchesKey(targetVoiceKey) ?? false) return;

    unawaited(() async {
      final voices = await getInstalledVoices();
      final match = voices
          .where((v) => v.matchesKey(targetVoiceKey))
          .firstOrNull;
      if (match != null) {
        await setVoice(match);
      } else {
        if (_voice != null && !voices.any((v) => v.id == _voice!.id)) {
          _voice = null;
          if (!_voiceController.isClosed) {
            _voiceController.add(null);
          }
        }
      }
    }());
  }

  Future<List<TtsVoiceOption>> getInstalledVoices() async {
    _cachedInstalledVoices = await _engineRegistry.getAllInstalledVoices();
    if (!_voicesController.isClosed) {
      _voicesController.add(_cachedInstalledVoices);
    }
    return _cachedInstalledVoices;
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    if (!_rateController.isClosed) {
      _rateController.add(rate);
    }
    await _audioPlayer.setSpeed(rate);

    final currentSettings = _settingsService.settings;
    if ((currentSettings.globalViewSettings.ttsRate - rate).abs() >= 0.001) {
      _settingsService.scheduleSave(
        currentSettings.copyWith(
          globalViewSettings: currentSettings.globalViewSettings.copyWith(
            ttsRate: rate,
          ),
        ),
      );
    }
  }

  /// Persists the sleep-timer duration as a [GlobalViewSettings] preference.
  /// A zero/negative duration disables the timer.
  void setSleepTimer(Duration duration) {
    final minutes = duration.inMinutes;
    final currentSettings = _settingsService.settings;
    if (currentSettings.globalViewSettings.ttsSleepTimerMinutes != minutes) {
      _settingsService.scheduleSave(
        currentSettings.copyWith(
          globalViewSettings: currentSettings.globalViewSettings.copyWith(
            ttsSleepTimerMinutes: minutes,
          ),
        ),
      );
    }
  }

  /// Last persisted sleep-timer duration in minutes (-1 or 0 = off).
  int get sleepTimerMinutes =>
      _settingsService.settings.globalViewSettings.ttsSleepTimerMinutes;

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    if (!_pitchController.isClosed) {
      _pitchController.add(pitch);
    }
    await _audioPlayer.setPitch(pitch);

    final currentSettings = _settingsService.settings;
    if ((currentSettings.globalViewSettings.ttsPitch - pitch).abs() >= 0.001) {
      _settingsService.scheduleSave(
        currentSettings.copyWith(
          globalViewSettings: currentSettings.globalViewSettings.copyWith(
            ttsPitch: pitch,
          ),
        ),
      );
    }
  }

  Future<void> setVoice(TtsVoiceOption voice) async {
    final voiceChanged = _voice != voice;
    _voice = voice;
    if (!_voiceController.isClosed) {
      _voiceController.add(voice);
    }

    // Persist selected voice to settings
    final currentSettings = _settingsService.settings;
    if (currentSettings.globalViewSettings.ttsVoice != voice.storageKey) {
      await _settingsService.save(
        currentSettings.copyWith(
          globalViewSettings: currentSettings.globalViewSettings.copyWith(
            ttsVoice: voice.storageKey,
          ),
        ),
      );
    }

    if (voiceChanged) {
      final engine = _engineRegistry.getEngineForVoice(voice);
      await engine.initialize();

      // If playback is currently active (playing or paused), re-synthesize from current chunk with new voice
      final isPlaying =
          _stateController.value.state == TtsPlaybackState.playing;
      final isPaused = _stateController.value.state == TtsPlaybackState.paused;
      if (_masterQueue.isNotEmpty && (isPlaying || isPaused)) {
        final cur = _currentIndex >= 0 ? _currentIndex : _lastKnownIndex;
        final sessionId = ++_activeSessionId;
        await _audioPlayer.stopSession();
        await _cleanTempFiles();
        _pipelineDone = false;
        unawaited(
          _synthesizeAndPlayPipeline(
            sessionId,
            cur,
            _baseTag,
            autoPlay: isPlaying,
          ),
        );
      }
    }
  }
}
