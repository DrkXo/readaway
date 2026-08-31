// ignore_for_file: experimental_member_use

part of 'services.dart';

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

  /// The shared player. Only valid after DI setup: `configureDependencies()`
  /// awaits this service's `init()`.
  AudioPlayer get player {
    final p = _player;
    if (p == null) {
      throw StateError(
        'JustAudioService.player accessed before init() completed.',
      );
    }
    return p;
  }

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
  ///
  /// The PCM->WAV encode is offloaded to a background isolate via
  /// [compute] and cached on the source, so it happens once — not once per
  /// just_audio range `request()` call, and not on the UI thread — which
  /// matters once you're playing back audio from a large model where a
  /// synthesized clip can be tens of millions of samples.
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

  // just_audio can call request() more than once (e.g. re-buffering); cache
  // the encode so that only happens once per clip.
  Future<Uint8List>? _wavBytesFuture;

  Future<Uint8List> get _wavBytes => _wavBytesFuture ??= compute(
    encodeTtsWav,
    WavEncodeArgs(audio.samples, audio.sampleRate),
  );

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final wavBytes = await _wavBytes;
    final s = start ?? 0;
    final e = end ?? wavBytes.length;
    return StreamAudioResponse(
      sourceLength: wavBytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(wavBytes.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}

class WavEncodeArgs {
  const WavEncodeArgs(this.samples, this.sampleRate);
  final Float32List samples;
  final int sampleRate;
}

/// Encodes [args] as a 16-bit PCM mono WAV. Top-level (not a method) so it
/// can be handed to [compute] and run on a background isolate.
///
/// Uses a single preallocated [Uint8List]/[ByteData] instead of a growable
/// `List<int>` built up with per-sample `.add()` calls — for a long clip
/// (hundreds of thousands to millions of samples) that difference is the
/// gap between an imperceptible encode and a multi-second stall.
Uint8List encodeTtsWav(WavEncodeArgs args) {
  final samples = args.samples;
  final sampleRate = args.sampleRate;
  final dataSize = samples.length * 2;
  final buffer = Uint8List(44 + dataSize);
  final bd = ByteData.view(buffer.buffer);

  void writeAscii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      buffer[offset + i] = s.codeUnitAt(i);
    }
  }

  writeAscii(0, 'RIFF');
  bd.setUint32(4, 36 + dataSize, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  bd.setUint16(32, 2, Endian.little); // block align
  bd.setUint16(34, 16, Endian.little); // bits per sample
  writeAscii(36, 'data');
  bd.setUint32(40, dataSize, Endian.little);

  var offset = 44;
  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    // Asymmetric scaling: full negative range reaches -32768, not -32767.
    final intSample = clamped < 0
        ? (clamped * 32768).round()
        : (clamped * 32767).round();
    bd.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  return buffer;
}
