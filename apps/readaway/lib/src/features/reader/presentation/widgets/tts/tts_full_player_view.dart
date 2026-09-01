part of '../reader_widgets.dart';

/// Full Player View with scrollable sentence queue & bottom-anchored controls.
///
/// The sentence list is driven by [TtsControllerService.queue] and rebuilds
/// whenever the queue version or the current chunk changes. Tapping a
/// sentence seeks playback to that chunk.
class TtsFullPlayerView extends StatelessWidget {
  const TtsFullPlayerView({
    required this.onClose,
    required this.onClosePlayer,
    required this.onDragUpdate,
    required this.onDragEnd,
    super.key,
  });

  /// Collapses the sheet back to the mini player.
  final VoidCallback onClose;

  /// Fully closes and disposes the TTS player.
  final VoidCallback onClosePlayer;

  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<ReaderBloc>().ttsController;
    return SafeArea(
      child: Column(
        children: [
          // 1. Top Drag Handle & Title Bar (Fixed at top)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      tooltip: 'Minimize',
                      onPressed: onClose,
                    ),
                    const Expanded(
                      child: Text(
                        'Sentences',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close Player',
                      onPressed: onClosePlayer,
                    ),
                  ],
                ),
                const Divider(height: 1),
              ],
            ),
          ),

          // 2. Scrollable Sentence Queue
          Expanded(
            child: StreamBuilder<Object?>(
              // Rebuilds when the queue is (re)built or the current chunk
              // changes, so the highlight tracks playback.
              stream: Rx.combineLatest2<int, TtsChunk?, (int, TtsChunk?)>(
                tts.queueVersion,
                tts.currentChunk.cast<TtsChunk?>().startWith(null),
                (version, chunk) => (version, chunk),
              ),
              builder: (context, snapshot) {
                final queue = tts.queue;
                final currentIndex = tts.currentChunkIndex;
                if (queue.isEmpty) {
                  return const Center(child: Text('Preparing sentences…'));
                }
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final chunk = queue[index];
                          final isCurrent = index == currentIndex;
                          final scheme = Theme.of(context).colorScheme;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: isCurrent
                                  ? scheme.primary
                                  : scheme.surfaceContainerHighest,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrent
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            title: Text(
                              chunk.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isCurrent ? scheme.primary : null,
                              ),
                            ),
                            onTap: () => tts.seekToChunk(index),
                          );
                        },
                        childCount: queue.length,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. Anchored Bottom Media Controls Section
          _BottomPlayerControls(
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
          ),
        ],
      ),
    );
  }
}

/// Bottom-anchored controls view with optional gesture handle area.
class _BottomPlayerControls extends StatelessWidget {
  const _BottomPlayerControls({
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tts = context.read<ReaderBloc>().ttsController;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<TtsChunk>(
              stream: tts.currentChunk,
              builder: (context, snapshot) {
                final text = snapshot.data?.text ?? 'Preparing…';
                return Row(
                  children: [
                    const Icon(Icons.multitrack_audio, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(tts.currentChunkIndex ?? 0) + 1} / ${tts.queueLength}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final isPlaying =
                    snapshot.data?.state == TtsPlaybackState.playing;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.skip_previous),
                      tooltip: 'Previous sentence',
                      onPressed: tts.skipToPreviousSentence,
                    ),
                    IconButton(
                      iconSize: 52,
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
                    ),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.skip_next),
                      tooltip: 'Next sentence',
                      onPressed: tts.skipToNextSentence,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
