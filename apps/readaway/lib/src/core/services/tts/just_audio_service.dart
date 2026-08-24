// ignore_for_file: experimental_member_use

part of '../services.dart';

/// Injectable wrapper around a single shared [AudioPlayer] (just_audio).
///
/// On Linux/Windows just_audio needs the media_kit backend, so this service
/// calls [JustAudioMediaKit.ensureInitialized] in its `@PostConstruct`
/// (preResolve) before the player is ever created. Everything audio-playback
/// related — TTS chunks, voice previews — should go through this instance
/// instead of spinning up its own player.
@singleton
class JustAudioService {
  AudioPlayer? _player;
  bool _initialized = false;

  /// The shared player. Safe after DI setup: `configureDependencies()`
  /// awaits this service's `init()`.
  AudioPlayer get player => _player!;

  /// Playback lifecycle of the shared player — use for completion detection,
  /// pause/resume UI, etc.
  Stream<PlayerState> get playerState => player.playerStateStream;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // media_kit backend for Linux/Windows desktop; no-op on mobile/web.
    JustAudioMediaKit.ensureInitialized(
      linux: true, // default: true  - dependency: media_kit_libs_linux
      windows:
          true, // default: true  - dependency: media_kit_libs_windows_audio
      android:
          true, // default: false - dependency: media_kit_libs_android_audio
      iOS: true, // default: false - dependency: media_kit_libs_ios_audio
      macOS: true, // default: false - dependency: media_kit_libs_macos_audio
    );
    _player = AudioPlayer();
  }

  /// Plays raw float32 mono PCM ([TtsAudio]) without a temp-file round trip.
  Future<void> playPcm(TtsAudio audio) async {
    await player.stop();
    await player.setAudioSource(_Float32PcmSource(audio));
    await player.play();
  }

  Future<void> playFile(String path) async {
    await player.stop();
    await player.setFilePath(path);
    await player.play();
  }

  Future<void> pause() => player.pause();
  Future<void> resume() => player.play();
  Future<void> stop() => player.stop();

  @disposeMethod
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}

/// Feeds raw float32 PCM samples from [TtsAudio] into just_audio without a
/// round-trip through a temp WAV file.
class _Float32PcmSource extends StreamAudioSource {
  _Float32PcmSource(this.audio) : super(tag: 'sherpa-tts-chunk');

  final TtsAudio audio;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final wavBytes = _encodeWav(audio);
    start ??= 0;
    end ??= wavBytes.length;
    return StreamAudioResponse(
      sourceLength: wavBytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(wavBytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}

/// Minimal 16-bit PCM WAV encoder for a [TtsAudio] sample buffer.
List<int> _encodeWav(TtsAudio audio) {
  final samples = audio.samples;
  final byteData = <int>[];
  final dataSize = samples.length * 2;

  void writeString(String s) => byteData.addAll(s.codeUnits);
  void writeUint32(int v) {
    byteData
      ..add(v & 0xff)
      ..add((v >> 8) & 0xff)
      ..add((v >> 16) & 0xff)
      ..add((v >> 24) & 0xff);
  }

  void writeUint16(int v) {
    byteData
      ..add(v & 0xff)
      ..add((v >> 8) & 0xff);
  }

  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(audio.sampleRate);
  writeUint32(audio.sampleRate * 2);
  writeUint16(2);
  writeUint16(16);
  writeString('data');
  writeUint32(dataSize);

  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    final intSample = (clamped * 32767).round();
    writeUint16(intSample & 0xffff);
  }

  return byteData;
}
