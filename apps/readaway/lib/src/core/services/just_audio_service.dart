// ignore_for_file: experimental_member_use

part of 'services.dart';

class WavEncodeArgs {
  const WavEncodeArgs(this.samples, this.sampleRate);
  final Float32List samples;
  final int sampleRate;
}

abstract class WavEncoder {
  static Uint8List encode(WavEncodeArgs args) {
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
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    var offset = 44;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i].clamp(-1.0, 1.0);
      final intSample = s < 0 ? (s * 32768).round() : (s * 32767).round();
      bd.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer;
  }
}

class PcmAudioSource extends StreamAudioSource {
  PcmAudioSource(this.audio) : super(tag: audio.chunkId ?? 'tts-pcm-chunk');

  final TtsAudio audio;
  Future<Uint8List>? _bytesFuture;

  Future<Uint8List> _getWavBytes() {
    return _bytesFuture ??= () {
      final args = WavEncodeArgs(audio.samples, audio.sampleRate);
      if (audio.durationInSeconds <= 3.0) {
        return Future.value(WavEncoder.encode(args));
      } else {
        return compute(WavEncoder.encode, args);
      }
    }();
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final bytes = await _getWavBytes();
    final s = start ?? 0;
    final e = end ?? bytes.length;

    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(bytes.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}

// --- Service Implementation ---

@singleton
class JustAudioService {
  AudioPlayer? _sessionPlayer;
  AudioPlayer? _previewPlayer;
  bool _initialized = false;

  /// Stream of current active index in the queue (e.g. tracking sentence/paragraph index)
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  /// Player state stream
  Stream<PlayerState> get sessionStateStream => player.playerStateStream;

  AudioPlayer get player {
    final p = _sessionPlayer;
    if (p == null) {
      throw StateError('JustAudioService accessed before init() completed.');
    }
    return p;
  }

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: true,
      android: true,
      iOS: true,
      macOS: true,
    );

    _sessionPlayer = AudioPlayer();
    _previewPlayer = AudioPlayer();
  }

  // ==========================================
  // CONTINUOUS TTS QUEUE METHODS (Modern API)
  // ==========================================

  /// Initializes a new gapless TTS playback session using setAudioSources.
  Future<void> startSession({List<TtsAudio>? initialChunks}) async {
    await stopSession();

    final sources = initialChunks?.map((c) => PcmAudioSource(c)).toList() ?? [];

    // Modern replace for ConcatenatingAudioSource
    await player.setAudioSources(
      sources,
      preload: true,
    );

    if (sources.isNotEmpty) {
      await player.play();
    }
  }

  /// Dynamically appends a synthesized PCM chunk to the active queue.
  Future<void> enqueueChunk(TtsAudio audio) async {
    final source = PcmAudioSource(audio);

    // Add source directly to AudioPlayer's dynamic queue
    await player.addAudioSource(source);

    // Auto-resume if queue was previously completed or empty
    if (!player.playing &&
        player.processingState == ProcessingState.completed) {
      await player.play();
    }
  }

  /// Appends multiple PCM chunks to the active queue.
  Future<void> enqueueChunks(List<TtsAudio> audioList) async {
    final sources = audioList.map((a) => PcmAudioSource(a)).toList();
    await player.addAudioSources(sources);

    if (!player.playing &&
        player.processingState == ProcessingState.completed) {
      await player.play();
    }
  }

  /// Skip directly to a specific sentence/chunk index.
  Future<void> seekToChunk(int index) async {
    await player.seek(Duration.zero, index: index);
  }

  /// Stop playback and wipe the active session queue completely.
  Future<void> stopSession() async {
    await player.stop();
    await player.clearAudioSources();
  }

  // ==========================================
  // PREVIEW & INDIVIDUAL CONTROLS
  // ==========================================

  Future<void> playPreview(TtsAudio audio) async {
    final preview = _previewPlayer;
    if (preview == null) return;

    await preview.stop();
    await preview.setAudioSource(PcmAudioSource(audio));
    await preview.play();
  }

  Future<void> pause() => player.pause();
  Future<void> resume() => player.play();

  @disposeMethod
  void dispose() {
    _sessionPlayer?.dispose();
    _previewPlayer?.dispose();
    _sessionPlayer = null;
    _previewPlayer = null;
  }
}
