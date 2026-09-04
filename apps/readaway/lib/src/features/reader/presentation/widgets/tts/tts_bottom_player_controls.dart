import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import 'live_speech_waveform.dart';
import 'tts_speed_control_panel.dart';
import 'waveform_scrubber.dart';

/// Bottom-anchored controls view with scrubber, speed button, and playback transport controls.
class TtsBottomPlayerControls extends StatefulWidget {
  const TtsBottomPlayerControls({
    required this.tts,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final TtsControllerService tts;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  @override
  State<TtsBottomPlayerControls> createState() =>
      _TtsBottomPlayerControlsState();
}

class _TtsBottomPlayerControlsState extends State<TtsBottomPlayerControls> {
  bool _showSpeedPanel = false;
  late final Stream<(PositionData, List<double>)> _waveformStream;

  @override
  void initState() {
    super.initState();
    // Hoist combined stream creation out of build() to prevent recreation and memory thrashing
    _waveformStream = Rx.combineLatest2<PositionData, List<double>,
        (PositionData, List<double>)>(
      widget.tts.positionDataStream,
      widget.tts.currentWaveform,
      (posData, waveform) => (posData, waveform),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tts = widget.tts;

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
              stream: _waveformStream,
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
