// ignore_for_file: experimental_member_use

part of '../../services.dart';

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
  PcmAudioSource(this.audio, {MediaItem? tag})
    : super(
        tag:
            tag ??
            MediaItem(
              id: audio.chunkId ?? UniqueKey().toString(),
              title: 'TTS Chunk',
              album: 'Speech Session',
            ),
      );
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

class JAAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  JAAudioHandler(this._player) {
    _initStreams();
  }

  final AudioPlayer _player;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<SequenceState?>? _sequenceSubscription;

  void _initStreams() {
    // Combine player state and position streams into AudioService PlaybackState
    _playbackStateSubscription =
        Rx.combineLatest2<PlayerState, Duration, PlaybackState>(
          _player.playerStateStream,
          _player.positionStream,
          (playerState, position) {
            final processingState = playerState.processingState;
            final playing = playerState.playing;

            return PlaybackState(
              controls: [
                MediaControl.skipToPrevious,
                if (playing) MediaControl.pause else MediaControl.play,
                MediaControl.stop,
                MediaControl.skipToNext,
              ],
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              androidCompactActionIndices: const [0, 1, 3],
              processingState: const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[processingState]!,
              playing: playing,
              updatePosition: position,
              bufferedPosition: _player.bufferedPosition,
              speed: _player.speed,
              queueIndex: _player.currentIndex,
            );
          },
        ).listen((state) {
          playbackState.add(state);
        });

    // Sync current queue and MediaItem metadata with AudioService
    _sequenceSubscription = _player.sequenceStateStream.listen((
      sequenceState,
    ) {
      final sequence = sequenceState.sequence;
      final queueItems = sequence.mapIndexed((index, source) {
        final tag = source.tag;
        if (tag is MediaItem) return tag;
        return MediaItem(
          id: '$index',
          title: 'Chunk ${index + 1}',
          album: 'TTS Session',
        );
      }).toList();

      queue.add(queueItems);

      final currentIndex = sequenceState.currentIndex;
      if (currentIndex != null &&
          currentIndex >= 0 &&
          currentIndex < queueItems.length) {
        mediaItem.add(queueItems[currentIndex]);
      }
    });
  }

  /// Transport "stop" — stops playback and tells AudioService the session
  /// ended (this is what actually clears/updates the notification). Safe
  /// to call repeatedly across many sessions: it does NOT cancel the
  /// handler's internal subscriptions, because this handler is a
  /// long-lived singleton reused for the app's lifetime, not recreated
  /// per session.
  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /// Real teardown of internal stream subscriptions. Only call this when
  /// the whole app/service is shutting down — never between sessions,
  /// since this handler instance is reused for the app's lifetime.
  Future<void> shutdown() async {
    await _playbackStateSubscription?.cancel();
    await _sequenceSubscription?.cancel();
    _playbackStateSubscription = null;
    _sequenceSubscription = null;
  }
}

/// A unified representation of an output audio device across platforms.
///
/// Wraps the platform-specific device types ([AudioDevice] from
/// `audio_session` on mobile, [mk.AudioDevice] from `media_kit` on desktop)
/// behind a single [id] + [name] surface so UI can render a consistent
/// device list without branching on platform.
class OutputAudioDevice extends Equatable {
  const OutputAudioDevice({
    required this.id,
    required this.name,
    this.native,
  });

  /// Stable identifier used to match the currently-selected device.
  final String id;

  /// Human-readable device name shown in the UI.
  final String name;

  /// The platform-specific device this wraps (mobile [AudioDevice] or
  /// desktop [mk.AudioDevice]).
  final Object? native;

  OutputAudioDevice.mobile(AudioDevice device)
    : id = device.id,
      name = device.name,
      native = device;

  OutputAudioDevice.desktop(mk.AudioDevice device)
    : id = device.name,
      name = device.description.isNotEmpty ? device.description : device.name,
      native = device;

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [id, name, native];
}
