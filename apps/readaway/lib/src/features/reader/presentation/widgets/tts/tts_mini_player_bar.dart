part of '../reader_widgets.dart';

/// Mini Player Bar widget with play/pause and close controls.
///
/// Shows the currently-playing sentence and toggles playback from the
/// [TtsControllerService] playback state stream. Closing dispatches
/// [ReaderEvent.ttsClose] via [onClosePlayer].
class TtsMiniPlayerBar extends StatelessWidget {
  const TtsMiniPlayerBar({
    required this.onClosePlayer,
    super.key,
  });

  final VoidCallback onClosePlayer;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<ReaderBloc>().ttsController;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<TtsChunk>(
              stream: tts.currentChunk,
              builder: (context, snapshot) {
                final text = snapshot.data?.text ?? 'Preparing…';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Drag ↑ / ↓ anywhere • Tap bar to open • Swipe ←/→ skip',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
          ),
          StreamBuilder<TtsPlaybackEvent>(
            stream: tts.playbackState,
            builder: (context, snapshot) {
              final isPlaying =
                  snapshot.data?.state == TtsPlaybackState.playing;
              return IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: () {
                  if (isPlaying) {
                    tts.pause();
                  } else {
                    tts.resume();
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close Player',
            onPressed: onClosePlayer,
          ),
        ],
      ),
    );
  }
}
