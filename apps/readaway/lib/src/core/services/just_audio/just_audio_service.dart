// ignore_for_file: experimental_member_use

part of '../services.dart';

// Helper extension for indexing mapping
extension _IterableIndexed<T> on Iterable<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) {
    var i = 0;
    return map((item) => f(i++, item)).toList();
  }
}

JustAudioService get justAudioService => GetIt.I<JustAudioService>();

@Singleton(
  dependsOn: [
    LoggingService,
    NotificationService,
    PackageInfoService,
  ],
)
class JustAudioService {
  final PackageInfoService _packageInfoService;
  final NotificationService _notificationService;

  JustAudioService(this._packageInfoService, this._notificationService);

  // The AudioService handler is a long-lived singleton for the app's
  // entire lifetime. AudioService.init() can only be called ONCE per
  // process — recreating it on every session was the source of crashes
  // / broken notification controls after the first TTS session.
  JAAudioHandler? _audioHandler;

  late final AudioPlayer _sessionPlayer;

  // Reused instance for one-off previews so we don't leak native players.
  AudioPlayer? _previewPlayer;

  // Auto-ends the session (and hides the notification) once the queue
  // finishes playing, instead of leaving a stale "completed" notification.
  StreamSubscription<ProcessingState>? _completionSubscription;

  bool _initialized = false;
  late final AudioSession _audioSessionInstance;

  AudioSessionConfiguration get _audioSessionConfig =>
      AudioSessionConfiguration.speech();

  Stream<int?> get currentIndexStream => player.currentIndexStream;
  Stream<PlayerState> get sessionStateStream => player.playerStateStream;

  AudioPlayer get player => _sessionPlayer;

  /// Whether the current platform is a desktop OS (Linux/Windows/macOS).
  bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (_initialized) return;

    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: true,
    );

    JustAudioMediaKit.title = F.name;

    // JustAudioMediaKit.mpvLogLevel = mk.MPVLogLevel.info;

    _audioSessionInstance = await AudioSession.instance;

    _sessionPlayer = AudioPlayer();

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

    // Create the handler ONCE, up front, and reuse it for every TTS
    // session for the rest of the app's lifetime.
    _audioHandler = await AudioService.init(
      builder: () => JAAudioHandler(player),
      config: AudioServiceConfig(
        androidNotificationChannelId: _notificationService.defaultChannelId,
        androidNotificationChannelName: _notificationService.defaultChannelName,
        androidNotificationIcon: _notificationService.defaultIcon,
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );

    _completionSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Cleanly end the session/notification once the last chunk
        // finishes, rather than leaving a stale "completed" state around.
        unawaited(stopSession());
      }
    });

    _initialized = true;
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

  /// Returns the available output devices as a unified [OutputAudioDevice]
  /// list, regardless of platform.
  ///
  /// On desktop this enumerates native media_kit devices (prefixed with an
  /// "Auto" entry for automatic selection); on mobile it enumerates
  /// `audio_session` output devices.
  Future<List<OutputAudioDevice>> getOutputDevices() async {
    if (isDesktop) {
      final devices = await getDesktopOutputDevices();
      return _cleanDesktopDevices(devices);
    }
    final devices = await getMobileOutputDevices();
    return [for (final d in devices) OutputAudioDevice.mobile(d)];
  }

  /// Filters the raw media_kit device list down to the real, user-facing
  /// output devices and deduplicates them.
  ///
  /// media_kit (via mpv) returns a large list that includes virtual ALSA
  /// plugin devices (rate converters, upmix/downmix, surround, etc.) and
  /// duplicate entries for the same hardware across backends (e.g. both
  /// `pipewire/...` and `pulse/...`). This keeps only meaningful devices,
  /// uses their friendly description for display, and collapses duplicates
  /// that share the same underlying hardware id.
  List<OutputAudioDevice> _cleanDesktopDevices(List<mk.AudioDevice> devices) {
    // Always offer automatic selection first.
    final result = <OutputAudioDevice>[
      const OutputAudioDevice(id: 'auto', name: 'Auto'),
    ];

    // Track seen hardware ids (the part after the last '/') to dedupe
    // pipewire/pulse/alsa variants of the same device.
    final seen = <String>{};

    for (final device in devices) {
      // Skip the media_kit-provided auto entry — we add our own above.
      if (device.name == 'auto') continue;

      // Skip generic "Default (X)" virtual devices (jack, openal, sdl, ...).
      if (device.description.startsWith('Default (')) continue;

      // Skip known ALSA plugin / virtual devices that aren't real outputs.
      if (_isAlsaPlugin(device.name)) continue;

      // Dedupe by the hardware id (suffix after the last '/').
      final hardwareId = device.name.contains('/')
          ? device.name.substring(device.name.lastIndexOf('/') + 1)
          : device.name;
      if (!seen.add(hardwareId)) continue;

      result.add(OutputAudioDevice.desktop(device));
    }

    return result;
  }

  /// Whether a media_kit device name refers to a virtual ALSA plugin rather
  /// than a real output device.
  bool _isAlsaPlugin(String name) {
    // Bare protocol names (no '/') are virtual "default" devices.
    if (!name.contains('/')) return true;

    // ALSA plugin devices that aren't real hardware outputs.
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
      // Surround virtual devices (surround21, surround40, ...) are plugins.
      if (plugin.startsWith('surround')) return true;
      return plugins.contains(plugin);
    }
    return false;
  }

  /// Selects an output device previously returned by [getOutputDevices].
  ///
  /// Routes to the platform-appropriate setter: [setDesktopAudioDevice] on
  /// desktop (with "auto" mapping to [mk.AudioDevice.auto]), or
  /// [setMobileSpeakerOutput] on mobile (speaker vs. non-speaker routing).
  Future<void> setOutputDevice(OutputAudioDevice device) async {
    if (isDesktop) {
      if (device.id == 'auto') {
        await setDesktopAudioDevice(mk.AudioDevice.auto());
      } else if (device.native case final mk.AudioDevice native) {
        await setDesktopAudioDevice(native);
      }
    } else {
      // Mobile: only speaker vs. non-speaker routing is supported.
      final isSpeaker = device.id == 'builtin_speaker';
      await setMobileSpeakerOutput(useSpeaker: isSpeaker);
    }
  }

  // ==========================================
  // SESSION CONTROLS
  // ==========================================

  Future<void> startSession({List<TtsAudio>? initialChunks}) async {
    await player.stop();
    await player.clearAudioSources();

    await _audioSessionInstance.configure(_audioSessionConfig);
    await _audioSessionInstance.setActive(true);

    final sources =
        initialChunks
            ?.mapIndexed(
              (i, c) => PcmAudioSource(
                c,
                tag: MediaItem(
                  id: '$i',
                  title: 'Chunk ${i + 1}',
                  album: 'TTS Session',
                ),
              ),
            )
            .toList() ??
        [];

    await player.setAudioSources(sources, preload: true);

    if (sources.isNotEmpty) {
      await player.play();
    }
  }

  Future<void> enqueueChunk(TtsAudio audio, [MediaItem? tag]) async {
    final isQueueEmpty = player.sequence.isEmpty;
    final index = player.sequence.length;

    final source = PcmAudioSource(
      audio,
      tag:
          tag ??
          MediaItem(
            id: '$index',
            title: '${index + 1}',
            album: 'TTS Session',
          ),
    );

    await player.addAudioSource(source);

    final shouldStart =
        isQueueEmpty ||
        (!player.playing &&
            player.processingState == ProcessingState.completed);

    if (shouldStart) {
      await player.play();
    }
  }

  Future<void> enqueueChunks(List<TtsAudio> audioList, [MediaItem? tag]) async {
    if (audioList.isEmpty) return;

    final isQueueEmpty = player.sequence.isEmpty;
    var startIndex = player.sequence.length;

    final sources = audioList
        .map(
          (a) => PcmAudioSource(
            a,
            tag:
                tag ??
                MediaItem(
                  id: '$startIndex',
                  title: 'Chunk ${++startIndex}',
                  album: 'TTS Session',
                ),
          ),
        )
        .toList();

    await player.addAudioSources(sources);

    final shouldStart =
        isQueueEmpty ||
        (!player.playing &&
            player.processingState == ProcessingState.completed);

    if (shouldStart) {
      await player.play();
    }
  }

  Future<void> seekToChunk(int index) async {
    await player.seek(Duration.zero, index: index);
  }

  /// Ends the current TTS session: stops playback, clears the queue,
  /// deactivates the audio session, and tells AudioService the session
  /// ended (hiding the notification per `androidStopForegroundOnPause`).
  ///
  /// Note: this does NOT tear down `_audioHandler` itself — it's reused
  /// for the next `startSession()` call, since AudioService.init() can
  /// only ever run once for the app's lifetime.
  Future<void> stopSession() async {
    await _audioHandler?.stop();
    await player.clearAudioSources();
    await _audioSessionInstance.setActive(false);
  }

  // ==========================================
  // PREVIEW & INDIVIDUAL CONTROLS
  // ==========================================

  Future<void> playPreview(TtsAudio audio) async {
    // Dispose any previous preview player instead of leaking a new native
    // player instance on every call.
    final old = _previewPlayer;
    _previewPlayer = null;
    await old?.dispose();

    final preview = AudioPlayer();
    _previewPlayer = preview;

    await preview.setAudioSource(PcmAudioSource(audio));
    await preview.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() => player.play();

  @disposeMethod
  Future<void> dispose() async {
    try {
      await _completionSubscription?.cancel();

      await _previewPlayer?.dispose();

      await _sessionPlayer.stop();

      await _audioSessionInstance.setActive(false);

      // Real teardown of the handler's internal subscriptions — only do
      // this when the whole service (app) is going away, never between
      // sessions.
      await _audioHandler?.shutdown();
    } catch (_) {
      // Ignore errors during teardown
    } finally {
      await _sessionPlayer.dispose();

      _previewPlayer = null;

      _audioHandler = null;
    }
  }
}
