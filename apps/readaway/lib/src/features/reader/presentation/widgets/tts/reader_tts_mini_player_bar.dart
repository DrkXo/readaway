import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';

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
            Icon(LucideIcons.audioWaveform, size: 24, color: scheme.primary),
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
