import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';

/// Full Player View with scrollable sentence queue & bottom-anchored controls.
class ReaderTtsFullPlayerView extends StatelessWidget {
  const ReaderTtsFullPlayerView({
    required this.onClose,
    required this.onClosePlayer,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onClosePlayer;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<ReaderBloc>().ttsController;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // 1. Top Drag Handle & Title Bar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: LucideIcons.chevronDown,
                        tooltip: 'Minimize',
                        onPressed: onClose,
                        size: AppIconButtonSize.medium,
                      ),
                      const Expanded(
                        child: AppText(
                          'Sentences',
                          variant: AppTextVariant.title,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppIconButton(
                        icon: LucideIcons.x,
                        tooltip: 'Close Player',
                        onPressed: onClosePlayer,
                        size: AppIconButtonSize.medium,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // 2. Scrollable Sentence Queue
          Expanded(
            child: StreamBuilder<Object?>(
              stream: Rx.combineLatest2<int, TtsChunk?, (int, TtsChunk?)>(
                tts.queueVersion,
                tts.currentChunk.cast<TtsChunk?>().startWith(null),
                (version, chunk) => (version, chunk),
              ),
              builder: (context, snapshot) {
                final queue = tts.queue;
                final currentIndex = tts.currentChunkIndex;

                if (queue.isEmpty) {
                  return const AppLoadingView(
                    label: 'Preparing sentences…',
                    compact: true,
                  );
                }

                return ListView.builder(
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
                                    color: scheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  )
                                : Border.all(color: Colors.transparent),
                          ),
                          child: ListTile(
                            tileColor: isCurrent
                                ? scheme.primaryContainer.withValues(alpha: 0.4)
                                : Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              isCurrent
                                  ? LucideIcons.cornerDownRight
                                  : LucideIcons.dot,
                              color: isCurrent
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              size: isCurrent ? 20 : 16,
                            ),
                            title: AppText(
                              chunk.text,
                              variant: AppTextVariant.body,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? scheme.onSurface
                                  : scheme.onSurface.withValues(alpha: 0.8),
                            ),
                            onTap: () => tts.seekToChunk(index),
                          ),
                        ),
                      ),
                    );
                  },
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

/// Bottom-anchored controls view with explicit play button hierarchy.
class _BottomPlayerControls extends StatelessWidget {
  const _BottomPlayerControls({
    this.onDragUpdate,
    this.onDragEnd,
  });

  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tts = context.read<ReaderBloc>().ttsController;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: context.appColors.shadowMd,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<TtsChunk>(
              stream: tts.currentChunk,
              builder: (context, snapshot) {
                final text = snapshot.data?.text ?? 'Preparing…';
                final index = (tts.currentChunkIndex ?? 0) + 1;
                final total = tts.queueLength;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.audioWaveform,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text,
                            variant: AppTextVariant.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 2),
                          AppCaption(
                            'Sentence $index of $total',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final isPlaying =
                    snapshot.data?.state == TtsPlaybackState.playing;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AppIconButton(
                      icon: LucideIcons.skipBack,
                      tooltip: 'Previous sentence',
                      onPressed: tts.skipToPreviousSentence,
                      size: AppIconButtonSize.large,
                    ),
                    IconButton.filled(
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                      ),
                      icon: Icon(
                        isPlaying ? LucideIcons.pause : LucideIcons.play,
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
                    AppIconButton(
                      icon: LucideIcons.skipForward,
                      tooltip: 'Next sentence',
                      onPressed: tts.skipToNextSentence,
                      size: AppIconButtonSize.large,
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
