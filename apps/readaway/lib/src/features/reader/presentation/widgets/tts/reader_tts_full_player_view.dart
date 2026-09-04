import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import 'live_speech_waveform.dart';
import 'tts_speed_control_panel.dart';
import 'waveform_scrubber.dart';

/// Full Player View with scrollable auto-centering sentence queue,
/// intra-sentence position scrubber, speed controls, and bottom-anchored controls.
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

          // 2. Scrollable Auto-Tracking Sentence Queue
          Expanded(
            child: _SentenceQueueList(tts: tts),
          ),

          // 3. Anchored Bottom Media Controls Section
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BottomPlayerControls(
              onDragUpdate: onDragUpdate,
              onDragEnd: onDragEnd,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable sentence queue list that smoothly centers on the active reading sentence.
class _SentenceQueueList extends StatefulWidget {
  const _SentenceQueueList({required this.tts});

  final TtsControllerService tts;

  @override
  State<_SentenceQueueList> createState() => _SentenceQueueListState();
}

class _SentenceQueueListState extends State<_SentenceQueueList> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<TtsChunk>? _chunkSub;
  int _lastIndex = -1;

  @override
  void initState() {
    super.initState();
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

    return StreamBuilder<Object?>(
      stream: Rx.combineLatest3<int, TtsChunk?, TtsPlaybackEvent,
          (int, TtsChunk?, bool)>(
        widget.tts.queueVersion,
        widget.tts.currentChunk.cast<TtsChunk?>().startWith(null),
        widget.tts.playbackState,
        (version, chunk, event) =>
            (version, chunk, event.state == TtsPlaybackState.playing),
      ),
      builder: (context, snapshot) {
        final queue = widget.tts.queue;
        final currentIndex = widget.tts.currentChunkIndex;
        final isPlaying =
            (snapshot.data as (int, TtsChunk?, bool)?)?.$3 ?? false;

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

/// Bottom-anchored controls view with scrubber, speed button, and playback transport controls.
class _BottomPlayerControls extends StatefulWidget {
  const _BottomPlayerControls({
    this.onDragUpdate,
    this.onDragEnd,
  });

  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  @override
  State<_BottomPlayerControls> createState() => _BottomPlayerControlsState();
}

class _BottomPlayerControlsState extends State<_BottomPlayerControls> {
  bool _showSpeedPanel = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tts = context.read<ReaderBloc>().ttsController;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: widget.onDragUpdate,
      onVerticalDragEnd: widget.onDragEnd,
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Current Active Sentence Info
            StreamBuilder<TtsChunk>(
              stream: tts.currentChunk,
              builder: (context, snapshot) {
                final text = snapshot.data?.text ?? 'Preparing…';
                final index = (tts.currentChunkIndex ?? 0) + 1;
                final total = tts.queueLength;

                return Row(
                  children: [
                    StreamBuilder<TtsPlaybackEvent>(
                      stream: tts.playbackState,
                      builder: (context, eventSnap) {
                        final isPlaying =
                            eventSnap.data?.state == TtsPlaybackState.playing;
                        final artUri = tts.baseTag?.artUri;
                        if (artUri != null && artUri.scheme == 'file') {
                          final coverFile = File(artUri.toFilePath());
                          return Stack(
                            alignment: Alignment.bottomRight,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.16),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    coverFile,
                                    width: 44,
                                    height: 58,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: LiveSpeechWaveform(
                                        isPlaying: isPlaying,
                                        color: scheme.primary,
                                        barCount: 4,
                                        height: 18,
                                        width: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isPlaying)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          scheme.surface.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: scheme.outlineVariant
                                            .withValues(alpha: 0.4),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: LiveSpeechWaveform(
                                      isPlaying: true,
                                      color: scheme.primary,
                                      barCount: 3,
                                      height: 10,
                                      width: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }
                        return Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer
                                .withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: LiveSpeechWaveform(
                              isPlaying: isPlaying,
                              color: scheme.primary,
                              barCount: 4,
                              height: 18,
                              width: 22,
                            ),
                          ),
                        );
                      },
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

            // 2. Error Display Banner (if error occurred)
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final event = snapshot.data;
                if (event?.state == TtsPlaybackState.error &&
                    event?.message != null) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          size: 16,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event!.message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onErrorContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 12),

            // 3. Intra-Sentence Interactive Waveform Progress Scrubber
            StreamBuilder<(PositionData, List<double>)>(
              stream: Rx.combineLatest2<PositionData, List<double>,
                  (PositionData, List<double>)>(
                tts.positionDataStream,
                tts.currentWaveform,
                (posData, waveform) => (posData, waveform),
              ),
              builder: (context, snapshot) {
                final posData = snapshot.data?.$1;
                final waveform = snapshot.data?.$2 ?? const [];
                final pos = posData?.position ?? Duration.zero;
                final dur = posData?.duration ?? Duration.zero;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: WaveformScrubber(
                    position: pos,
                    duration: dur,
                    waveform: waveform,
                    onSeek: (target) => tts.seek(target),
                  ),
                );
              },
            ),

            const SizedBox(height: 6),

            // 3b. Expandable Speech Rate Controller Panel
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _showSpeedPanel
                  ? StreamBuilder<double>(
                      stream: tts.rateStream,
                      initialData: tts.rate,
                      builder: (context, rateSnap) {
                        final rate = rateSnap.data ?? 1.0;
                        return TtsSpeedControlPanel(
                          rate: rate,
                          onRateChanged: (newRate) => tts.setRate(newRate),
                          onClose: () {
                            setState(() => _showSpeedPanel = false);
                          },
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 6),

            // 4. Transport Control Row with Speed Pill and Playback Buttons
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final isPlaying =
                    snapshot.data?.state == TtsPlaybackState.playing;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Playback Speed Selector Pill (toggles speed controller panel)
                    StreamBuilder<double>(
                      stream: tts.rateStream,
                      initialData: tts.rate,
                      builder: (context, rateSnap) {
                        final rate = rateSnap.data ?? 1.0;
                        final label = TtsSpeedControlPanel.formatRate(rate);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _showSpeedPanel = !_showSpeedPanel;
                            });
                          },
                          onLongPress: () {
                            tts.setRate(1.0);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _showSpeedPanel
                                  ? scheme.primary
                                  : scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _showSpeedPanel
                                    ? scheme.primary
                                    : scheme.outlineVariant
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.gauge,
                                  size: 13,
                                  color: _showSpeedPanel
                                      ? scheme.onPrimary
                                      : scheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: _showSpeedPanel
                                        ? scheme.onPrimary
                                        : scheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  _showSpeedPanel
                                      ? LucideIcons.chevronDown
                                      : LucideIcons.chevronUp,
                                  size: 13,
                                  color: _showSpeedPanel
                                      ? scheme.onPrimary.withValues(alpha: 0.8)
                                      : scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Skip Previous Sentence
                    AppIconButton(
                      icon: LucideIcons.skipBack,
                      tooltip: 'Previous sentence',
                      onPressed: tts.skipToPreviousSentence,
                      size: AppIconButtonSize.large,
                    ),

                    // Play / Pause Button
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

                    // Skip Next Sentence
                    AppIconButton(
                      icon: LucideIcons.skipForward,
                      tooltip: 'Next sentence',
                      onPressed: tts.skipToNextSentence,
                      size: AppIconButtonSize.large,
                    ),

                    // Stop / Reset Session Button
                    AppIconButton(
                      icon: LucideIcons.square,
                      tooltip: 'Stop',
                      onPressed: tts.stop,
                      size: AppIconButtonSize.medium,
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
