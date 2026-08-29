import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../../../reader/presentation/bloc/reader_bloc.dart';
import '../bloc/tts_player_bloc.dart';
import '../pages/tts_player_page.dart';

/// Compact "now playing" bar docked above the reader's bottom bar with
/// full gesture support (swipe to skip, pull up to expand).
class TtsMiniPlayer extends StatelessWidget {
  const TtsMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TtsPlayerBloc>.value(
      value: GetIt.I<TtsPlayerBloc>(),
      child: BlocBuilder<TtsPlayerBloc, TtsPlayerState>(
        buildWhen: (prev, curr) =>
            prev.isActive != curr.isActive ||
            prev.playbackState != curr.playbackState ||
            prev.currentSentenceText != curr.currentSentenceText ||
            prev.currentChunkIndex != curr.currentChunkIndex ||
            prev.chunkCount != curr.chunkCount ||
            prev.currentPageIndex != curr.currentPageIndex,
        builder: (context, state) {
          if (!state.isActive) return const SizedBox.shrink();

          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final borderRadius = BorderRadius.circular(14);

          return Positioned(
            left: 8,
            right: 8,
            bottom: 48,
            child: OpenContainer(
              transitionType: ContainerTransitionType.fade,
              transitionDuration: const Duration(milliseconds: 300),
              closedElevation: 0,
              openElevation: 0,
              closedColor: Colors.transparent,
              openColor: scheme.surface,
              closedShape: RoundedRectangleBorder(borderRadius: borderRadius),
              tappable: false,
              openBuilder: (context, action) => TtsPlayerPage(onClose: action),
              closedBuilder: (context, action) => Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  // Vertical drag up opens full player
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! < -300) {
                      action();
                    }
                  },
                  // Horizontal swipe skips tracks
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    final bloc = context.read<TtsPlayerBloc>();
                    if (details.primaryVelocity! < -300) {
                      // Swipe Left -> Next sentence
                      bloc.add(const TtsPlayerEvent.nextSentence());
                    } else if (details.primaryVelocity! > 300) {
                      // Swipe Right -> Previous sentence
                      bloc.add(const TtsPlayerEvent.previousSentence());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh.withValues(
                        alpha: 0.96,
                      ),
                      borderRadius: borderRadius,
                      boxShadow: context.appColors.shadowMd,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: state.isPlaying ? 'Pause' : 'Play',
                          icon: Icon(
                            state.isPlaying
                                ? LucideIcons.pause
                                : LucideIcons.play,
                          ),
                          onPressed: () => context.read<TtsPlayerBloc>().add(
                            const TtsPlayerEvent.playPause(),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Previous sentence',
                          icon: const Icon(LucideIcons.skipBack),
                          onPressed: () => context.read<TtsPlayerBloc>().add(
                            const TtsPlayerEvent.previousSentence(),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next sentence',
                          icon: const Icon(LucideIcons.skipForward),
                          onPressed: () => context.read<TtsPlayerBloc>().add(
                            const TtsPlayerEvent.nextSentence(),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: action,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Page ${state.currentPageIndex + 1} · '
                                  'sentence ${state.currentChunkIndex + 1}/${state.chunkCount}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                  child: Text(
                                    state.currentSentenceText ?? '',
                                    key: ValueKey(
                                      state.currentSentenceText ?? '',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Play from current page',
                          icon: const Icon(LucideIcons.rotateCcw),
                          onPressed: () {
                            final page = context
                                .read<ReaderBloc>()
                                .state
                                .currentPage;
                            context.read<TtsPlayerBloc>().add(
                              TtsPlayerEvent.playFromPage(page),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Close player',
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => context.read<TtsPlayerBloc>().add(
                            const TtsPlayerEvent.closePlayer(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
