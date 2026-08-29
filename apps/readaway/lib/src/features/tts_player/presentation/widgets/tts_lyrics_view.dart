import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/tts_player_bloc.dart';

/// Scrollable "lyrics" list of the current page's sentences.
/// Highlights the active sentence, dims inactive text, supports multi-line sentences,
/// and reliably centers the playing sentence during playback.
class TtsLyricsView extends StatefulWidget {
  const TtsLyricsView({super.key});

  @override
  State<TtsLyricsView> createState() => _TtsLyricsViewState();
}

class _TtsLyricsViewState extends State<TtsLyricsView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, double> _itemHeights = {};
  int _lastCenteredIndex = -1;
  List<String>? _lastSentences;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerOn(int index) {
    if (index == _lastCenteredIndex || !_scrollController.hasClients) return;
    _lastCenteredIndex = index;

    final viewport = _scrollController.position.viewportDimension;

    // Calculate vertical offset up to the active item based on recorded heights
    double targetOffset = 0.0;
    for (int i = 0; i < index; i++) {
      targetOffset += _itemHeights[i] ?? 60.0; // fallback height estimate
    }

    final currentItemHeight = _itemHeights[index] ?? 60.0;
    final centeredTarget =
        (targetOffset - (viewport / 2) + (currentItemHeight / 2)).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

    _scrollController.animateTo(
      centeredTarget,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TtsPlayerBloc>.value(
      value: GetIt.I.get<TtsPlayerBloc>(),
      child: BlocConsumer<TtsPlayerBloc, TtsPlayerState>(
        listenWhen: (prev, curr) =>
            prev.currentChunkIndex != curr.currentChunkIndex ||
            prev.pageSentences != curr.pageSentences,
        listener: (context, state) {
          if (!identical(_lastSentences, state.pageSentences)) {
            _lastSentences = state.pageSentences;
            _lastCenteredIndex = -1;
            _itemHeights.clear();
          }

          if (state.currentChunkIndex >= 0) {
            _centerOn(state.currentChunkIndex);
          }
        },
        buildWhen: (prev, curr) =>
            prev.pageSentences != curr.pageSentences ||
            prev.currentChunkIndex != curr.currentChunkIndex ||
            prev.loading != curr.loading ||
            prev.error != curr.error,
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }

          final sentences = state.pageSentences;
          if (sentences.isEmpty) {
            return const Center(child: Text('No text on this page yet.'));
          }

          final activeIndex = state.currentChunkIndex;

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
            itemCount: sentences.length,
            itemBuilder: (context, index) {
              return _MeasuredItem(
                onSizeMeasured: (size) {
                  _itemHeights[index] = size.height;
                },
                child: _LyricsLine(
                  text: sentences[index],
                  isActive: index == activeIndex,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LyricsLine extends StatelessWidget {
  const _LyricsLine({
    required this.text,
    required this.isActive,
  });

  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isActive ? 1.0 : 0.35, // Dims non-playing text clearly
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          style: isActive
              ? theme.textTheme.headlineSmall!.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                )
              : theme.textTheme.titleMedium!.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true, // Shows full text without clipping/overflow
          ),
        ),
      ),
    );
  }
}

/// Utility widget to measure sentence height dynamically without hardcoding itemExtent
class _MeasuredItem extends StatefulWidget {
  const _MeasuredItem({
    required this.child,
    required this.onSizeMeasured,
  });

  final Widget child;
  final ValueChanged<Size> onSizeMeasured;

  @override
  State<_MeasuredItem> createState() => _MeasuredItemState();
}

class _MeasuredItemState extends State<_MeasuredItem> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      widget.onSizeMeasured(renderBox.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
