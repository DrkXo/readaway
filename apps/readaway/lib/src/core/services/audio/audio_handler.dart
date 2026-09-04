import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// Helper extension for indexed mapping
extension on Iterable {
  List<R> mapIndexed<T, R>(R Function(int index, T item) f) {
    var i = 0;
    return map((item) => f(i++, item as T)).toList();
  }
}

/// Bridges [AudioPlayer] with the system's background audio service and notification.
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

            final audioProcessingState = switch (processingState) {
              ProcessingState.idle => AudioProcessingState.idle,
              ProcessingState.loading => AudioProcessingState.loading,
              ProcessingState.buffering => AudioProcessingState.buffering,
              ProcessingState.ready => AudioProcessingState.ready,
              ProcessingState.completed => AudioProcessingState.completed,
            };

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
              processingState: audioProcessingState,
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
      final queueItems = sequence.mapIndexed<IndexedAudioSource, MediaItem>((
        index,
        source,
      ) {
        final tag = source.tag;
        if (tag is MediaItem) return tag;
        return MediaItem(
          id: '$index',
          title: 'Track ${index + 1}',
          album: 'Audio Session',
        );
      });

      queue.add(queueItems);

      final currentIndex = sequenceState.currentIndex;
      if (currentIndex != null && currentIndex >= 0 && currentIndex < queueItems.length) {
        mediaItem.add(queueItems[currentIndex]);
      }
    });
  }

  /// Transport "stop" — stops playback and tells AudioService the session ended.
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

  /// Teardown of internal stream subscriptions on app shutdown.
  Future<void> shutdown() async {
    await _playbackStateSubscription?.cancel();
    await _sequenceSubscription?.cancel();
    _playbackStateSubscription = null;
    _sequenceSubscription = null;
  }
}
