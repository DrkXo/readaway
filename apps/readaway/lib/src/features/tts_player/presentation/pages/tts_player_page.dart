import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../reader/presentation/bloc/reader_bloc.dart';
import '../bloc/tts_player_bloc.dart';
import '../widgets/tts_lyrics_view.dart';
import '../widgets/tts_pitch_slider.dart';
import '../widgets/tts_rate_slider.dart';
import '../widgets/tts_sleep_timer.dart';
import '../widgets/tts_voice_picker.dart';

/// Full-screen TTS player with vertical drag-to-dismiss support.
class TtsPlayerPage extends StatefulWidget {
  const TtsPlayerPage({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<TtsPlayerPage> createState() => _TtsPlayerPageState();
}

class _TtsPlayerPageState extends State<TtsPlayerPage> {
  double _dragOffsetY = 0.0;

  void _dismiss() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Calculate interactive scale and opacity based on drag distance
    final dragProgress = (_dragOffsetY / 300).clamp(0.0, 1.0);
    final scale =
        1.0 - (dragProgress * 0.08); // Slightly scale down while dragging

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Only track downward drags
        if (details.delta.dy > 0 || _dragOffsetY > 0) {
          setState(() {
            _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(0.0, 400.0);
          });
        }
      },
      onVerticalDragEnd: (details) {
        // Dismiss if dragged down past threshold (120px) or flung downwards fast
        if (_dragOffsetY > 120 || details.velocity.pixelsPerSecond.dy > 800) {
          _dismiss();
        } else {
          // Snap back to top if threshold wasn't reached
          setState(() {
            _dragOffsetY = 0.0;
          });
        }
      },
      child: AnimatedContainer(
        duration: _dragOffsetY == 0
            ? const Duration(milliseconds: 200)
            : Duration.zero,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _dragOffsetY, 0)..scale(scale),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            // Drag handle visually indicates to the user that down-swipe works
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const _PlayerTitle(),
              ],
            ),
            leading: IconButton(
              tooltip: 'Close player',
              icon: const Icon(LucideIcons.chevronDown),
              onPressed: _dismiss,
            ),
            actions: [
              IconButton(
                tooltip: 'Audio Settings',
                icon: const Icon(LucideIcons.slidersHorizontal),
                onPressed: () => _showAudioSettingsSheet(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TtsLyricsView(),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _TransportRow(),
                        const SizedBox(height: 16),
                        const TtsVoicePicker(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(child: TtsSleepTimer()),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              tooltip: 'Play from current reader page',
                              icon: const Icon(LucideIcons.rotateCcw, size: 18),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAudioSettingsSheet(BuildContext context) {
    final bloc = context.read<TtsPlayerBloc>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      sheetContext,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Audio Fine-Tuning',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const TtsRateSlider(),
              const SizedBox(height: 8),
              const TtsPitchSlider(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerTitle extends StatelessWidget {
  const _PlayerTitle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TtsPlayerBloc, TtsPlayerState>(
      buildWhen: (prev, curr) =>
          prev.currentPageIndex != curr.currentPageIndex ||
          prev.totalPages != curr.totalPages ||
          prev.currentChunkIndex != curr.currentChunkIndex ||
          prev.chunkCount != curr.chunkCount,
      builder: (context, state) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Text to Speech', style: theme.textTheme.titleMedium),
            Text(
              'Page ${state.currentPageIndex + 1} of ${state.totalPages} · '
              'sentence ${state.currentChunkIndex + 1}/${state.chunkCount}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TtsPlayerBloc, TtsPlayerState>(
      buildWhen: (prev, curr) => prev.playbackState != curr.playbackState,
      builder: (context, state) {
        final bloc = context.read<TtsPlayerBloc>();
        final scheme = Theme.of(context).colorScheme;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Stop',
              iconSize: 24,
              icon: const Icon(LucideIcons.square),
              onPressed: () => bloc.add(const TtsPlayerEvent.stop()),
            ),
            IconButton(
              tooltip: 'Previous sentence',
              iconSize: 28,
              icon: const Icon(LucideIcons.skipBack),
              onPressed: () =>
                  bloc.add(const TtsPlayerEvent.previousSentence()),
            ),
            IconButton.filled(
              style: IconButton.styleFrom(
                minimumSize: const Size(64, 64),
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
              tooltip: state.isPlaying ? 'Pause' : 'Play',
              iconSize: 32,
              icon: Icon(
                state.isPlaying ? LucideIcons.pause : LucideIcons.play,
              ),
              onPressed: () => bloc.add(const TtsPlayerEvent.playPause()),
            ),
            IconButton(
              tooltip: 'Next sentence',
              iconSize: 28,
              icon: const Icon(LucideIcons.skipForward),
              onPressed: () => bloc.add(const TtsPlayerEvent.nextSentence()),
            ),
            IconButton(
              tooltip: 'Audio Settings',
              iconSize: 24,
              icon: const Icon(LucideIcons.slidersHorizontal),
              onPressed: () {
                final state = context
                    .findAncestorStateOfType<_TtsPlayerPageState>();
                if (state != null) {
                  state._showAudioSettingsSheet(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
