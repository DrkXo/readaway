import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_service_mpris/audio_service_mpris.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:media_kit/media_kit.dart' as mk hide PlayerState;
import 'package:mutex/mutex.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../flavors.dart';
import '../../error/errors.dart';
import '../logging_service.dart';
import '../notification_service.dart';
import '../package_info_service.dart';
import 'audio_device.dart';
import 'audio_handler.dart';

/// Combined playback position, buffered position, and total duration for player UI.
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(this.position, this.bufferedPosition, this.duration);
}

typedef JustAudioService = AudioPlayerService;

AudioPlayerService get audioPlayerService => GetIt.I<AudioPlayerService>();
JustAudioService get justAudioService => audioPlayerService;

/// Core Audio Service responsible solely for audio playback, playlist management,
/// audio session lifecycle, output devices, and background media controls.
///
/// Completely independent of TTS or reading logic.
@Singleton(
  dependsOn: [
    LoggingService,
    NotificationService,
    PackageInfoService,
  ],
)
class AudioPlayerService {
  final PackageInfoService _packageInfoService;
  final NotificationService _notificationService;

  AudioPlayerService(this._packageInfoService, this._notificationService);

  final Mutex _playlistMutex = Mutex();

  JAAudioHandler? _audioHandler;
  late final AudioPlayer _sessionPlayer;
  AudioPlayer? _previewPlayer;

  bool _initialized = false;
  late final AudioSession _audioSessionInstance;

  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;

  AudioSessionConfiguration get _audioSessionConfig =>
      AudioSessionConfiguration.speech();

  Stream<int?> get currentIndexStream => _sessionPlayer.currentIndexStream;
  Stream<PlayerState> get sessionStateStream => _sessionPlayer.playerStateStream;
  Stream<ProcessingState> get processingStateStream =>
      _sessionPlayer.processingStateStream;
  Stream<Duration> get positionStream => _sessionPlayer.positionStream;
  Stream<Duration?> get durationStream => _sessionPlayer.durationStream;
  Stream<SequenceState?> get sequenceStateStream =>
      _sessionPlayer.sequenceStateStream;

  /// Combined position, buffered position, and duration stream powered by RxDart.
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _sessionPlayer.positionStream,
        _sessionPlayer.bufferedPositionStream,
        _sessionPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  AudioPlayer get player => _sessionPlayer;
  Duration get position => _sessionPlayer.position;
  Duration? get duration => _sessionPlayer.duration;
  bool get isPlaying => _sessionPlayer.playing;
  int get playlistLength => _sessionPlayer.sequence.length;

  /// Whether the current platform is a desktop OS (Linux/Windows/macOS).
  bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (_initialized) return;

    try {
      JustAudioMediaKit.ensureInitialized(
        linux: true,
        windows: true,
      );

      JustAudioMediaKit.title = F.name;

      _audioSessionInstance = await AudioSession.instance;

      _sessionPlayer = AudioPlayer();
      await _sessionPlayer.setAudioSources([], preload: false);

      if (isDesktop && Platform.isLinux) {
        AudioServiceMpris.init(
          dBusName: _packageInfoService.packageName,
          identity: F.name,
          canGoNext: true,
          canGoPrevious: true,
          canPlay: true,
          canPause: true,
          canControl: true,
        );
      }

      // Initialize AudioService once for background notifications
      _audioHandler = await AudioService.init(
        builder: () => JAAudioHandler(_sessionPlayer),
        config: AudioServiceConfig(
          androidNotificationChannelId: _notificationService.defaultChannelId,
          androidNotificationChannelName:
              _notificationService.defaultChannelName,
          androidNotificationIcon:
              _notificationService.audioServiceNotificationIcon,
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
        ),
      );

      _setupAudioSessionListeners();
      _initialized = true;
    } catch (e, st) {
      logger.e('Failed to initialize AudioPlayerService', e, st);
      throw AudioPlaybackException('Failed to initialize AudioPlayerService', e);
    }
  }

  void _setupAudioSessionListeners() {
    // Auto-pause when headphones are unplugged
    _becomingNoisySub = _audioSessionInstance.becomingNoisyEventStream.listen((
      _,
    ) {
      if (_sessionPlayer.playing) {
        pause();
      }
    });

    // Handle interruptions (e.g., incoming phone calls)
    _interruptionSub = _audioSessionInstance.interruptionEventStream.listen((
      event,
    ) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _sessionPlayer.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_sessionPlayer.playing) {
              pause();
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _sessionPlayer.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            // Don't auto-resume unless user initiated
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  // ==========================================
  // PLAYLIST & PLAYBACK CONTROLS
  // ==========================================

  /// Replaces the active playlist atomically, activates the audio session, and optionally plays.
  Future<void> setPlaylist(
    List<AudioSource> initialSources, {
    int initialIndex = 0,
    bool autoPlay = true,
  }) => _playlistMutex.protect(() async {
    try {
      await _sessionPlayer.stop();

      await _audioSessionInstance.configure(_audioSessionConfig);
      await _audioSessionInstance.setActive(true);

      final validIndex = initialSources.isEmpty
          ? 0
          : initialIndex.clamp(0, initialSources.length - 1);

      await _sessionPlayer.setAudioSources(
        initialSources,
        initialIndex: validIndex,
        initialPosition: Duration.zero,
        preload: true,
      );

      if (autoPlay && initialSources.isNotEmpty) {
        await _audioSessionInstance.setActive(true);
        await _sessionPlayer.play();
      }
    } catch (e, st) {
      logger.e('Failed to set playlist in AudioPlayerService', e, st);
      throw AudioPlaybackException('Failed to set audio playlist', e);
    }
  });

  /// Appends an audio source to the playlist.
  /// If the player reached the end of the previous buffer, safely resumes playback.
  Future<void> appendSource(
    AudioSource source, {
    bool playIfIdle = false,
  }) => _playlistMutex.protect(() async {
    try {
      final wasEmpty = _sessionPlayer.sequence.isEmpty;
      await _sessionPlayer.addAudioSource(source);

      final processingState = _sessionPlayer.processingState;
      final isEnded = processingState == ProcessingState.completed;

      if (wasEmpty && playIfIdle) {
        await _sessionPlayer.play();
      } else if (isEnded && (_sessionPlayer.playing || playIfIdle)) {
        // ExoPlayer stalled at the end of the previous chunk; advance to newly appended item
        final nextIndex = _sessionPlayer.sequence.length - 1;
        await _sessionPlayer.seek(Duration.zero, index: nextIndex);
        await _sessionPlayer.play();
      }
    } catch (e, st) {
      logger.e('Failed to append audio source to playlist', e, st);
      throw AudioPlaybackException('Failed to append audio source', e);
    }
  });

  /// Appends multiple audio sources to the active playlist.
  Future<void> appendSources(
    List<AudioSource> sources, {
    bool playIfIdle = false,
  }) => _playlistMutex.protect(() async {
    if (sources.isEmpty) return;
    try {
      final wasEmpty = _sessionPlayer.sequence.isEmpty;
      await _sessionPlayer.addAudioSources(sources);

      final processingState = _sessionPlayer.processingState;
      final isEnded = processingState == ProcessingState.completed;

      if (wasEmpty && playIfIdle) {
        await _sessionPlayer.play();
      } else if (isEnded && (_sessionPlayer.playing || playIfIdle)) {
        final nextIndex = _sessionPlayer.sequence.length - sources.length;
        await _sessionPlayer.seek(Duration.zero, index: nextIndex);
        await _sessionPlayer.play();
      }
    } catch (e, st) {
      logger.e('Failed to append audio sources to playlist', e, st);
      throw AudioPlaybackException('Failed to append audio sources', e);
    }
  });

  /// Clears the active playlist and stops playback.
  Future<void> clearPlaylist() => _playlistMutex.protect(() async {
    try {
      await _sessionPlayer.stop();
      await _sessionPlayer.clearAudioSources();
    } catch (e, st) {
      logger.e('Failed to clear playlist', e, st);
      throw AudioPlaybackException('Failed to clear playlist', e);
    }
  });

  /// Seeks to a specific track index in the current playlist.
  Future<void> seekToIndex(int index, {Duration position = Duration.zero}) async {
    if (index < 0 || index >= _sessionPlayer.sequence.length) return;
    try {
      await _sessionPlayer.seek(position, index: index);
    } catch (e, st) {
      logger.e('Failed to seek to index $index', e, st);
      throw AudioPlaybackException('Failed to seek to track $index', e);
    }
  }

  /// Seeks to a position within the current track.
  Future<void> seek(Duration position) async {
    try {
      await _sessionPlayer.seek(position);
    } catch (e, st) {
      logger.e('Failed to seek to position $position', e, st);
      throw AudioPlaybackException('Failed to seek position', e);
    }
  }

  /// Sets playback speed multiplier (e.g. 0.75, 1.0, 1.25, 1.5, 2.0).
  Future<void> setSpeed(double speed) async {
    try {
      await _sessionPlayer.setSpeed(speed);
    } catch (e, st) {
      logger.e('Failed to set playback speed: $speed', e, st);
    }
  }

  double get speed => _sessionPlayer.speed;
  Stream<double> get speedStream => _sessionPlayer.speedStream;

  /// Sets playback volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    try {
      await _sessionPlayer.setVolume(volume);
    } catch (e, st) {
      logger.e('Failed to set volume: $volume', e, st);
    }
  }

  double get volume => _sessionPlayer.volume;
  Stream<double> get volumeStream => _sessionPlayer.volumeStream;

  Future<void> seekToNext() async {
    if (_sessionPlayer.hasNext) {
      try {
        await _sessionPlayer.seekToNext();
      } catch (e, st) {
        logger.e('Failed to seek to next track', e, st);
      }
    }
  }

  Future<void> seekToPrevious() async {
    if (_sessionPlayer.hasPrevious) {
      try {
        await _sessionPlayer.seekToPrevious();
      } catch (e, st) {
        logger.e('Failed to seek to previous track', e, st);
      }
    }
  }

  Future<void> play() async {
    try {
      await _audioSessionInstance.setActive(true);
      await _sessionPlayer.play();
    } catch (e, st) {
      logger.e('Failed to start audio playback', e, st);
      throw AudioPlaybackException('Failed to play audio', e);
    }
  }

  Future<void> pause() async {
    try {
      await _sessionPlayer.pause();
    } catch (e, st) {
      logger.e('Failed to pause playback', e, st);
    }
  }

  Future<void> resume() => play();

  /// Ends the current audio session, stops player, clears playlist, and deactivates AudioSession.
  Future<void> stopSession() => _playlistMutex.protect(() async {
    try {
      await _audioHandler?.stop();
      await _sessionPlayer.stop();
      await _sessionPlayer.clearAudioSources();
      await _audioSessionInstance.setActive(false);
    } catch (e, st) {
      logger.e('Failed to stop audio session cleanly', e, st);
    }
  });

  // ==========================================
  // PREVIEW PLAYER
  // ==========================================

  /// Plays a short one-off preview file without interfering with the active session playlist.
  Future<void> playPreviewFile(String filePath) async {
    try {
      final old = _previewPlayer;
      _previewPlayer = null;
      await old?.dispose();

      final preview = AudioPlayer();
      _previewPlayer = preview;

      await preview.setAudioSource(AudioSource.file(filePath));
      await preview.play();
    } catch (e, st) {
      logger.e('Failed to play preview file: $filePath', e, st);
      throw AudioPlaybackException('Failed to play preview audio file', e);
    }
  }

  // ==========================================
  // OUTPUT DEVICE CONTROL APIS
  // ==========================================

  Future<List<AudioDevice>> getMobileOutputDevices() async {
    final devices = await _audioSessionInstance.getDevices();
    return devices.where((d) => d.isOutput).toList();
  }

  Stream<AudioDevicesChangedEvent> get onAudioDevicesChanged =>
      _audioSessionInstance.devicesChangedEventStream;

  Future<void> setMobileSpeakerOutput({bool useSpeaker = true}) async {
    final config = useSpeaker
        ? _audioSessionConfig
        : const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playback,
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.allowBluetoothA2dp,
            androidAudioAttributes: AndroidAudioAttributes(
              contentType: AndroidAudioContentType.speech,
              usage: AndroidAudioUsage.media,
            ),
            androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          );

    await _audioSessionInstance.configure(config);
  }

  Future<List<mk.AudioDevice>> getDesktopOutputDevices() async => const [];

  Future<void> setDesktopAudioDevice(mk.AudioDevice device) async {}

  Future<List<OutputAudioDevice>> getOutputDevices() async {
    if (isDesktop) {
      final devices = await getDesktopOutputDevices();
      return _cleanDesktopDevices(devices);
    }
    final devices = await getMobileOutputDevices();
    return [for (final d in devices) OutputAudioDevice.mobile(d)];
  }

  List<OutputAudioDevice> _cleanDesktopDevices(List<mk.AudioDevice> devices) {
    final result = <OutputAudioDevice>[
      const OutputAudioDevice(id: 'auto', name: 'Auto'),
    ];

    final seen = <String>{};

    for (final device in devices) {
      if (device.name == 'auto') continue;
      if (device.description.startsWith('Default (')) continue;
      if (_isAlsaPlugin(device.name)) continue;

      final hardwareId = device.name.contains('/')
          ? device.name.substring(device.name.lastIndexOf('/') + 1)
          : device.name;
      if (!seen.add(hardwareId)) continue;

      result.add(OutputAudioDevice.desktop(device));
    }

    return result;
  }

  bool _isAlsaPlugin(String name) {
    if (!name.contains('/')) return true;

    const plugins = {
      'lavrate',
      'samplerate',
      'speexrate',
      'speex',
      'upmix',
      'vdownmix',
      'jack',
      'oss',
      'pipewire',
      'pulse',
    };
    if (name.startsWith('alsa/')) {
      final plugin = name.substring('alsa/'.length);
      if (plugin.startsWith('surround')) return true;
      return plugins.contains(plugin);
    }
    return false;
  }

  Future<void> setOutputDevice(OutputAudioDevice device) async {
    try {
      if (isDesktop) {
        if (device.id == 'auto') {
          await setDesktopAudioDevice(mk.AudioDevice.auto());
        } else if (device.native case final mk.AudioDevice native) {
          await setDesktopAudioDevice(native);
        }
      } else {
        final isSpeaker = device.id == 'builtin_speaker';
        await setMobileSpeakerOutput(useSpeaker: isSpeaker);
      }
    } catch (e, st) {
      logger.e('Failed to set output device: ${device.id}', e, st);
      throw AudioDeviceException('Failed to set output audio device', e);
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    try {
      await _interruptionSub?.cancel();
      await _becomingNoisySub?.cancel();
      await _previewPlayer?.dispose();
      await _sessionPlayer.stop();
      await _audioSessionInstance.setActive(false);
      await _audioHandler?.shutdown();
    } catch (_) {
    } finally {
      await _sessionPlayer.dispose();
      _previewPlayer = null;
      _audioHandler = null;
    }
  }
}
