import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

import '../logging_service.dart';
import '../path_service.dart';
import '../audio/audio_player_service.dart';
import 'sherpa/sherpa_onnx_tts_service.dart';
import 'tts_chunker_service.dart';
import 'tts_models.dart';

/// Manages the TTS playback pipeline: sentence chunking, lookahead synthesis,
/// native file caching, and gapless audio enqueue.
@lazySingleton
class TtsControllerService {
  TtsControllerService(
    this._sherpaTts,
    this._audioPlayer,
    this._chunkingService,
    this._pathService,
  );

  final SherpaOnnxTtsService _sherpaTts;
  final AudioPlayerService _audioPlayer;
  final TtsChunkingService _chunkingService;
  final AppPathService _pathService;

  final Mutex _pipelineMutex = Mutex();

  TtsVoiceOption? _voice;
  double _rate = 1.0;
  // ignore: unused_field
  double _pitch = 1.0;

  final _voiceController = BehaviorSubject<TtsVoiceOption?>.seeded(null);
  ValueStream<TtsVoiceOption?> get currentVoiceOption =>
      _voiceController.stream;

  List<TtsChunk> _masterQueue = [];
  int _currentIndex = -1;
  int _lastKnownIndex = 0;
  int _pipelineStartIndex = 0;

  int _activeSessionId = 0;
  MediaItem? _baseTag;
  MediaItem? get baseTag => _baseTag;
  final List<File> _sessionTempFiles = [];
  final Map<int, List<double>> _chunkWaveforms = {};

  final _stateController = BehaviorSubject<TtsPlaybackEvent>.seeded(
    const TtsPlaybackEvent(TtsPlaybackState.idle),
  );
  final _chunkController = BehaviorSubject<TtsChunk?>();

  /// Bumped whenever [_masterQueue] is (re)built so UI can rebuild its sentence list.
  final _queueController = BehaviorSubject<int>.seeded(0);
  final _rateController = BehaviorSubject<double>.seeded(1.0);
  final _waveformController = BehaviorSubject<List<double>>.seeded(const []);

  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _pipelineStarted = false;
  bool _pipelineDone = false;

  AudioPlayerService get audioPlayer => _audioPlayer;
  Stream<PositionData> get positionDataStream => _audioPlayer.positionDataStream;
  ValueStream<TtsPlaybackEvent> get playbackState => _stateController.stream;
  Stream<TtsChunk> get currentChunk => _chunkController.stream.whereNotNull();
  ValueStream<int> get queueVersion => _queueController.stream;
  ValueStream<List<double>> get currentWaveform => _waveformController.stream;
  double get rate => _rate;
  ValueStream<double> get rateStream => _rateController.stream;
  List<TtsChunk> get queue => List.unmodifiable(_masterQueue);
  int get queueLength => _masterQueue.length;
  int? get currentChunkIndex => _currentIndex >= 0
      ? _currentIndex
      : (_masterQueue.isNotEmpty &&
              _lastKnownIndex >= 0 &&
              _lastKnownIndex < _masterQueue.length
          ? _lastKnownIndex
          : null);
  TtsVoiceOption? get currentVoice => _voice;
  List<SherpaTtsModelInfo> get availableSherpaModels =>
      _sherpaTts.availableModels;

  /// Currently active [TtsChunk], if any.
  TtsChunk? get activeChunk => (currentChunkIndex != null &&
          currentChunkIndex! >= 0 &&
          currentChunkIndex! < _masterQueue.length)
      ? _masterQueue[currentChunkIndex!]
      : null;

  /// Whether the currently active chunk is the end of a paragraph.
  bool get isCurrentChunkParagraphEnd => activeChunk?.isParagraphEnd ?? false;

  /// Paragraph index of the currently active chunk.
  int? get currentParagraphIndex => activeChunk?.paragraphIndex;

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
        }
        // If not pipelineDone, player temporarily reached end of buffered items;
        // background synthesis is continuing and will append more.
      } else if (playerState.playing) {
        if (!_stateController.isClosed) {
          _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.playing));
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
    MediaItem? tag,
  }) => _pipelineMutex.protect(() async {
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

  /// Lookahead synthesis pipeline: pre-synthesizes initial buffer, starts playback,
  /// and continues queuing remaining chunks ahead of playback.
  Future<void> _synthesizeAndPlayPipeline(
    int sessionId,
    int startIndex,
    MediaItem? baseTag,
  ) async {
    _pipelineStartIndex = startIndex;
    _currentIndex = startIndex;
    _lastKnownIndex = startIndex;
    if (!_chunkController.isClosed && startIndex < _masterQueue.length) {
      _chunkController.add(_masterQueue[startIndex]);
    }
    try {
      final cacheDir = await _pathService.getTtsAudioCacheDirectory();

      // 1. Pre-buffer: synthesize up to 2 initial chunks before starting playback
      // to guarantee ExoPlayer never starves on Android.
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
        if (textToSpeak.trim().isEmpty) continue;

        final filePath = p.join(
          cacheDir.path,
          'chunk_${sessionId}_$i.wav',
        );

        try {
          final result = await _sherpaTts.generateToFile(
            text: textToSpeak,
            outputPath: filePath,
            speakerId: _voice?.sherpaSpeakerId ?? 0,
            speed: _rate <= 0 ? 1.0 : _rate,
          );
          consecutiveErrors = 0;
          if (sessionId != _activeSessionId) {
            await _deleteFileSafe(result.file);
            return;
          }
          _sessionTempFiles.add(result.file);
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

          initialSources.add(AudioSource.file(result.file.path, tag: mediaItem));
        } catch (e) {
          if (sessionId != _activeSessionId) return;
          consecutiveErrors++;
          logger.w('TTS pre-buffering skipped problematic chunk $i ($consecutiveErrors/$maxConsecutiveErrors)', e);
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
          autoPlay: true,
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
        if (textToSpeak.trim().isEmpty) continue;

        final filePath = p.join(
          cacheDir.path,
          'chunk_${sessionId}_$i.wav',
        );

        try {
          final result = await _sherpaTts.generateToFile(
            text: textToSpeak,
            outputPath: filePath,
            speakerId: _voice?.sherpaSpeakerId ?? 0,
            speed: _rate <= 0 ? 1.0 : _rate,
          );
          consecutiveErrors = 0;
          if (sessionId != _activeSessionId) {
            await _deleteFileSafe(result.file);
            return;
          }
          _sessionTempFiles.add(result.file);
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
            AudioSource.file(result.file.path, tag: mediaItem),
            playIfIdle: true,
          );
        } catch (e) {
          if (sessionId != _activeSessionId) return;
          consecutiveErrors++;
          logger.w('TTS synthesis skipped problematic chunk $i ($consecutiveErrors/$maxConsecutiveErrors)', e);
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

  void _resetPlaybackState() {
    _currentIndex = -1;
    if (!_stateController.isClosed) {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
    }
  }

  Future<void> _cleanTempFiles() async {
    final files = List<File>.from(_sessionTempFiles);
    _sessionTempFiles.clear();
    _chunkWaveforms.clear();
    if (!_waveformController.isClosed) {
      _waveformController.add(const []);
    }
    for (final f in files) {
      await _deleteFileSafe(f);
    }
  }

  Future<void> _deleteFileSafe(File f) async {
    try {
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
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

  /// Seeks to a position within the currently playing sentence track.
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> setRate(double rate) async {
    _rate = rate;
    if (!_rateController.isClosed) {
      _rateController.add(rate);
    }
    await _audioPlayer.setSpeed(rate);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
  }

  Future<void> setVoice(TtsVoiceOption voice) async {
    _voice = voice;
    if (!_voiceController.isClosed) {
      _voiceController.add(voice);
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    await stopPipeline();
    await _stateController.close();
    await _chunkController.close();
    await _queueController.close();
    await _voiceController.close();
    await _rateController.close();
    await _waveformController.close();
  }
}
