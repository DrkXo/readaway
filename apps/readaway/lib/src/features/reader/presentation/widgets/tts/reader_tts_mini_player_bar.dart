import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';

/// Mini Player Bar widget with play/pause and close controls.
///
/// Shows the currently-playing sentence and toggles playback from the
/// [TtsControllerService] playback state stream. Closing dispatches
/// [ReaderEvent.ttsClose] via [onClosePlayer].
class ReaderTtsMiniPlayerBar extends StatelessWidget {
  const ReaderTtsMiniPlayerBar({
    required this.onClosePlayer,
    super.key,
  });

  final VoidCallback onClosePlayer;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<ReaderBloc>().ttsController;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(LucideIcons.audioWaveform, size: 24, color: scheme.primary),
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
                    AppText(
                      text,
                      variant: AppTextVariant.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppCaption(
                      'Drag ↑ / ↓ anywhere • Tap bar to open • Swipe ←/→ skip',
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
                size: AppIconButtonSize.large,
              );
            },
          ),
          AppIconButton(
            icon: LucideIcons.x,
            tooltip: 'Close Player',
            onPressed: onClosePlayer,
            size: AppIconButtonSize.medium,
          ),
        ],
      ),
    );
  }
}
