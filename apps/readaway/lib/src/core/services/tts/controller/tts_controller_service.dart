import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../features/settings/domain/entity/settings.dart';
import '../../services.dart';

part 'tts_controller_service.cleanup.dart';
part 'tts_controller_service.pipeline.dart';
part 'tts_controller_service.playback.dart';
part 'tts_controller_service.voice.dart';

/// Manages the TTS playback pipeline: sentence chunking, lookahead synthesis,
/// native file caching, and gapless audio enqueue.
///
/// This class holds all shared state (queue, session id, controllers, etc.).
/// Its behavior is split by responsibility into part files, implemented as
/// extensions on [TtsControllerService] so they retain access to private
/// state without exposing it publicly:
///  - `tts_controller_service.voice.dart`    — voice/rate/pitch selection & settings sync
///  - `tts_controller_service.pipeline.dart` — lookahead synthesis pipeline
///  - `tts_controller_service.playback.dart` — transport controls (play/pause/seek/skip)
///  - `tts_controller_service.cleanup.dart`  — temp file & playback-state cleanup
@lazySingleton
class TtsControllerService {
  final _log = AppLogger.instance.scope('TtsControllerService');

  TtsControllerService(
    this._engineRegistry,
    this._audioPlayer,
    this._chunkingService,
    this._settingsService,
    this._cacheService,
  ) {
    final gvs = _settingsService.settings.globalViewSettings;
    _rate = gvs.ttsRate > 0 ? gvs.ttsRate : 1.0;
    _pitch = gvs.ttsPitch > 0 ? gvs.ttsPitch : 1.0;
    _rateController = BehaviorSubject<double>.seeded(_rate);
    _pitchController = BehaviorSubject<double>.seeded(_pitch);
    _settingsSubscription = _settingsService.changes.listen(_onSettingsChanged);
  }

  final TtsEngineRegistry _engineRegistry;
  final AudioPlayerService _audioPlayer;
  final TtsChunkingService _chunkingService;
  final SettingsService _settingsService;
  final TtsChapterCacheService _cacheService;

  StreamSubscription<Settings>? _settingsSubscription;

  final Mutex _pipelineMutex = Mutex();

  String? _currentBookPath;
  int? _currentSectionIndex;
  TtsChapterCacheManifest? _currentChapterManifest;

  TtsVoiceOption? _voice;
  double _rate = 1.0;
  double _pitch = 1.0;

  final _voiceController = BehaviorSubject<TtsVoiceOption?>.seeded(null);
  ValueStream<TtsVoiceOption?> get currentVoiceOption =>
      _voiceController.stream;

  final _voicesController = BehaviorSubject<List<TtsVoiceOption>>.seeded(
    const [],
  );
  ValueStream<List<TtsVoiceOption>> get availableVoicesStream =>
      _voicesController.stream;

  List<TtsChunk> _masterQueue = [];
  int _currentIndex = -1;
  int _lastKnownIndex = 0;
  int _pipelineStartIndex = 0;
  int? _currentPageIndex;
  int? get currentPageIndex => _currentPageIndex;
  final _pageIndexController = BehaviorSubject<int?>.seeded(null);
  ValueStream<int?> get currentPageIndexStream => _pageIndexController.stream;

  int _activeSessionId = 0;
  MediaItem? _baseTag;
  MediaItem? get baseTag => _baseTag;
  final Map<int, List<double>> _chunkWaveforms = {};

  final _stateController = BehaviorSubject<TtsPlaybackEvent>.seeded(
    const TtsPlaybackEvent(TtsPlaybackState.idle),
  );
  final _chunkController = BehaviorSubject<TtsChunk?>();

  /// Bumped whenever [_masterQueue] is (re)built so UI can rebuild its sentence list.
  final _queueController = BehaviorSubject<int>.seeded(0);
  late final BehaviorSubject<double> _rateController;
  late final BehaviorSubject<double> _pitchController;
  final _waveformController = BehaviorSubject<List<double>>.seeded(const []);

  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _pipelineStarted = false;
  bool _pipelineDone = false;

  AudioPlayerService get audioPlayer => _audioPlayer;
  Stream<PositionData> get positionDataStream =>
      _audioPlayer.positionDataStream;
  ValueStream<TtsPlaybackEvent> get playbackState => _stateController.stream;
  Stream<TtsChunk> get currentChunk => _chunkController.stream.whereNotNull();
  ValueStream<int> get queueVersion => _queueController.stream;
  ValueStream<List<double>> get currentWaveform => _waveformController.stream;
  double get rate => _rate;
  ValueStream<double> get rateStream => _rateController.stream;
  double get pitch => _pitch;
  ValueStream<double> get pitchStream => _pitchController.stream;
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
  List<TtsVoiceOption> _cachedInstalledVoices = const [];
  List<TtsVoiceOption> get availableVoices => _voicesController.value.isNotEmpty
      ? _voicesController.value
      : _cachedInstalledVoices;

  /// Currently active [TtsChunk], if any.
  TtsChunk? get activeChunk =>
      (currentChunkIndex != null &&
          currentChunkIndex! >= 0 &&
          currentChunkIndex! < _masterQueue.length)
      ? _masterQueue[currentChunkIndex!]
      : null;

  /// Whether the currently active chunk is the end of a paragraph.
  bool get isCurrentChunkParagraphEnd => activeChunk?.isParagraphEnd ?? false;

  /// Paragraph index of the currently active chunk.
  int? get currentParagraphIndex => activeChunk?.paragraphIndex;

  void Function()? _onPageCompletedCallback;
  void Function()? _onChapterNearEndCallback;

  void setOnChapterNearEndCallback(void Function()? callback) {
    _onChapterNearEndCallback = callback;
  }

  @disposeMethod
  Future<void> dispose() async {
    await releaseResources();
    _settingsSubscription?.cancel();
    await _stateController.close();
    await _chunkController.close();
    await _queueController.close();
    await _voiceController.close();
    await _voicesController.close();
    await _rateController.close();
    await _pitchController.close();
    await _waveformController.close();
    await _pageIndexController.close();
  }
}
