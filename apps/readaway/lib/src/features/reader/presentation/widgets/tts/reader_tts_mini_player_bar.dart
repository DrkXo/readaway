import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart' show TtsChunk;

import '../../../../../core/services/tts/tts_models.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/repositories/reader_tts_repository.dart';
import '../../bloc/reader_bloc.dart';
import '../../bloc/tts/reader_tts_bloc.dart';
import 'live_speech_waveform.dart';
import 'tts_sleep_timer_control.dart';

class ReaderTtsMiniPlayerBar extends StatelessWidget {
  const ReaderTtsMiniPlayerBar({
    required this.onClosePlayer,
    super.key,
  });

  final VoidCallback onClosePlayer;

  static const double height = 76;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final tts = context.read<ReaderTtsBloc>().ttsRepository;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MiniPlayerCover(tts: tts),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniPlayerText(tts: tts),
            ),
            const SizedBox(width: 8),
            _MiniPlayerPlayButton(tts: tts),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Close Player',
              child: Semantics(
                label: 'Close Player',
                button: true,
                child: MetroPressable(
                  onTap: onClosePlayer,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: appColors.topbarForeground.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayerCover extends StatelessWidget {
  const _MiniPlayerCover({required this.tts});

  final ReaderTtsRepository tts;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final scheme = appColors.scheme;

    return StreamBuilder<TtsPlaybackEvent>(
      stream: tts.playbackState,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.state == TtsPlaybackState.playing;
        final artUri = tts.baseTag?.artUri;

        if (artUri != null && artUri.scheme == 'file') {
          final coverFile = File(artUri.toFilePath());
          return Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: appColors.panelBorder,
                    width: 0.5,
                  ),
                ),
                child: ClipRect(
                  child: Image.file(
                    coverFile,
                    width: 36,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 36,
                      height: 48,
                      color: scheme.surfaceContainerHighest,
                      child: Center(
                        child: LiveSpeechWaveform(
                          isPlaying: isPlaying,
                          color: scheme.primary,
                          barCount: 3,
                          height: 16,
                          width: 16,
                        ),
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
                      horizontal: 2.5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: LiveSpeechWaveform(
                      isPlaying: true,
                      color: scheme.primary,
                      barCount: 3,
                      height: 8,
                      width: 10,
                    ),
                  ),
                ),
            ],
          );
        }

        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: appColors.panelBorder,
              width: 0.5,
            ),
          ),
          child: Center(
            child: LiveSpeechWaveform(
              isPlaying: isPlaying,
              color: scheme.primary,
              barCount: 4,
              height: 18,
              width: 20,
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerText extends StatelessWidget {
  const _MiniPlayerText({required this.tts});

  final ReaderTtsRepository tts;

  @override
  Widget build(BuildContext context) {
    final readerState = context.watch<ReaderBloc>().state;
    final ttsState = context.watch<ReaderTtsBloc>().state;

    final ttsPage = ttsState.ttsCurrentPage;
    final isOtherPage = ttsState.canJumpToTtsPage(
      currentPage: readerState.currentPage,
      currentVirtualPage: readerState.currentVirtualPage,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (ttsPage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isOtherPage
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  'p. ${ttsPage + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOtherPage
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: StreamBuilder<TtsChunk>(
                stream: tts.currentChunk,
                builder: (context, snapshot) {
                  final text = snapshot.data?.text ?? 'Preparing…';
                  return AppText(
                    text,
                    variant: AppTextVariant.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Builder(
          builder: (context) {
            final remaining = ttsState.ttsSleepTimerRemaining;
            return Row(
              children: [
                if (remaining != null) ...[
                  Icon(
                    LucideIcons.moonStar,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    formatSleepDuration(remaining),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: AppCaption(
                    isOtherPage
                        ? 'Playing on Page ${(ttsPage ?? 0) + 1} • Tap to open'
                        : 'Drag ↑ / ↓ • Tap to open • Swipe ←/→ skip',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MiniPlayerPlayButton extends StatelessWidget {
  const _MiniPlayerPlayButton({required this.tts});

  final ReaderTtsRepository tts;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return StreamBuilder<TtsPlaybackEvent>(
      stream: tts.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data?.state;
        final isPlaying = state == TtsPlaybackState.playing;
        final isLoading = state == TtsPlaybackState.loading;

        if (isLoading) {
          return SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: SpinKitPulsingGrid(
                color: appColors.buttonBackground,
                size: 20,
              ),
            ),
          );
        }

        return MetroPressable(
          onTap: () {
            if (isPlaying) {
              tts.pause();
            } else {
              tts.resume();
            }
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: appColors.buttonBackground,
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Icon(
                isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: appColors.buttonForeground,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
