import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import 'live_speech_waveform.dart';

/// Scrollable sentence queue list that smoothly centers on the active reading sentence.
class TtsSentenceQueueList extends StatefulWidget {
  const TtsSentenceQueueList({
    required this.tts,
    super.key,
  });

  final TtsControllerService tts;

  @override
  State<TtsSentenceQueueList> createState() => _TtsSentenceQueueListState();
}

class _TtsSentenceQueueListState extends State<TtsSentenceQueueList> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<TtsChunk>? _chunkSub;
  late final Stream<(int, TtsChunk?, bool)> _playbackStream;
  int _lastIndex = -1;

  @override
  void initState() {
    super.initState();
    // Hoist combined stream creation out of build() to prevent recreation and re-subscriptions
    _playbackStream = Rx.combineLatest3<int, TtsChunk?, TtsPlaybackEvent,
        (int, TtsChunk?, bool)>(
      widget.tts.queueVersion,
      widget.tts.currentChunk.cast<TtsChunk?>().startWith(null),
      widget.tts.playbackState,
      (version, chunk, event) =>
          (version, chunk, event.state == TtsPlaybackState.playing),
    );

    _chunkSub = widget.tts.currentChunk.listen((_) {
      _scrollToActiveIndex();
    });
  }

  @override
  void dispose() {
    _chunkSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex() {
    if (!mounted || !_scrollController.hasClients) return;
    final index = widget.tts.currentChunkIndex;
    if (index == null || index == _lastIndex) return;
    _lastIndex = index;

    // Approximate height per sentence tile: 76px
    const itemEstimatedHeight = 76.0;
    final targetOffset = (index * itemEstimatedHeight - 120.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<(int, TtsChunk?, bool)>(
      stream: _playbackStream,
      builder: (context, snapshot) {
        final queue = widget.tts.queue;
        final currentIndex = widget.tts.currentChunkIndex;
        final isPlaying = snapshot.data?.$3 ?? false;

        if (queue.isEmpty) {
          return const AppLoadingView(
            label: 'Preparing sentences…',
            compact: true,
          );
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final chunk = queue[index];
            final isCurrent = index == currentIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(
                            color: scheme.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          )
                        : Border.all(color: Colors.transparent),
                  ),
                  child: ListTile(
                    tileColor: isCurrent
                        ? scheme.primaryContainer.withValues(alpha: 0.35)
                        : Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: isCurrent
                        ? LiveSpeechWaveform(
                            isPlaying: isPlaying,
                            barCount: 3,
                            height: 16,
                            width: 16,
                            color: scheme.primary,
                          )
                        : Icon(
                            LucideIcons.dot,
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            size: 16,
                          ),
                    title: AppText(
                      chunk.text,
                      variant: AppTextVariant.body,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: isCurrent
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.8),
                    ),
                    onTap: () => widget.tts.seekToChunk(index),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
