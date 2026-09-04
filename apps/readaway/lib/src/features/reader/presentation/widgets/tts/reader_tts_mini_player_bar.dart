import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';

import 'live_speech_waveform.dart';

class ReaderTtsMiniPlayerBar extends StatelessWidget {
  const ReaderTtsMiniPlayerBar({
    required this.onClosePlayer,
    super.key,
  });

  final VoidCallback onClosePlayer;

  static const double height = 76;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<ReaderBloc>().ttsController;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final isPlaying =
                    snapshot.data?.state == TtsPlaybackState.playing;
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
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
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
                              borderRadius: BorderRadius.circular(3),
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
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<TtsChunk>(
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
                  const SizedBox(height: 2),
                  AppCaption(
                    'Drag ↑ / ↓ • Tap to open • Swipe ←/→ skip',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final isPlaying =
                    snapshot.data?.state == TtsPlaybackState.playing;
                return AppIconButton(
                  icon: isPlaying ? LucideIcons.pause : LucideIcons.play,
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: () {
                    if (isPlaying) {
                      tts.pause();
                    } else {
                      tts.resume();
                    }
                  },
                  size: AppIconButtonSize.medium,
                );
              },
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: LucideIcons.x,
              tooltip: 'Close Player',
              onPressed: onClosePlayer,
              size: AppIconButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }
}
