import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/tts/tts_chunk_model.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/repositories/reader_tts_repository.dart';
import 'live_speech_waveform.dart';

/// Scrollable sentence queue list that smoothly centers on the active reading sentence.
///
/// Performance optimizations:
/// - Full-list rebuild elimination: top-level builder only listens to `queueVersion`.
/// - Granular item updates: each item listens to `_currentIndexNotifier` and only rebuilds
///   when transitioning into or out of active state. All other items skip `build()`.
/// - Waveform paint isolation: `LiveSpeechWaveform` repaints are contained within `RepaintBoundary`.
/// - Jitter-free scrolling: uses `Scrollable.ensureVisible` for pixel-accurate alignment.
/// - Interaction awareness: auto-scrolling pauses while the user is dragging or browsing.
class TtsSentenceQueueList extends StatefulWidget {
  const TtsSentenceQueueList({
    required this.tts,
    super.key,
  });

  final ReaderTtsRepository tts;

  @override
  State<TtsSentenceQueueList> createState() => _TtsSentenceQueueListState();
}

class _TtsSentenceQueueListState extends State<TtsSentenceQueueList> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};

  late final ValueNotifier<int?> _currentIndexNotifier;
  late final ValueNotifier<bool> _isPlayingNotifier;

  StreamSubscription<TtsChunk>? _chunkSub;
  StreamSubscription<TtsPlaybackEvent>? _playbackSub;
  StreamSubscription<int>? _queueSub;

  bool _isUserScrolling = false;
  Timer? _userScrollTimer;
  int? _lastScrolledIndex;

  @override
  void initState() {
    super.initState();
    _currentIndexNotifier = ValueNotifier<int?>(widget.tts.currentChunkIndex);
    _isPlayingNotifier = ValueNotifier<bool>(false);

    _initSubscriptions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentIndex = widget.tts.currentChunkIndex;
      if (currentIndex != null) {
        _scrollToActiveIndex(currentIndex, userInitiated: true);
      }
    });
  }

  void _initSubscriptions() {
    _chunkSub = widget.tts.currentChunk.listen((_) {
      final newIndex = widget.tts.currentChunkIndex;
      if (newIndex != null && newIndex != _currentIndexNotifier.value) {
        _currentIndexNotifier.value = newIndex;
        _scrollToActiveIndex(newIndex);
      }
    });

    _playbackSub = widget.tts.playbackState.listen((event) {
      final isPlaying = event.state == TtsPlaybackState.playing;
      if (_isPlayingNotifier.value != isPlaying) {
        _isPlayingNotifier.value = isPlaying;
      }
    });

    _queueSub = widget.tts.queueVersion.listen((_) {
      _itemKeys.clear();
      final current = widget.tts.currentChunkIndex;
      _currentIndexNotifier.value = current;
      if (current != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveIndex(current, userInitiated: true);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant TtsSentenceQueueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tts != widget.tts) {
      _chunkSub?.cancel();
      _playbackSub?.cancel();
      _queueSub?.cancel();
      _itemKeys.clear();
      _currentIndexNotifier.value = widget.tts.currentChunkIndex;
      _initSubscriptions();
    }
  }

  @override
  void dispose() {
    _userScrollTimer?.cancel();
    _chunkSub?.cancel();
    _playbackSub?.cancel();
    _queueSub?.cancel();
    _scrollController.dispose();
    _currentIndexNotifier.dispose();
    _isPlayingNotifier.dispose();
    super.dispose();
  }

  GlobalKey _keyForIndex(int index) {
    return _itemKeys.putIfAbsent(index, () => GlobalKey());
  }

  void _scrollToActiveIndex(int index, {bool userInitiated = false}) {
    if (!mounted || !_scrollController.hasClients) return;
    if (!userInitiated && _isUserScrolling) return;
    if (!userInitiated && _lastScrolledIndex == index) return;

    _lastScrolledIndex = index;

    final key = _itemKeys[index];
    final targetContext = key?.currentContext;

    if (targetContext != null && targetContext.mounted) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.35,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Fallback jump if the target sentence is currently unmounted
      final queueLength = widget.tts.queueLength;
      if (queueLength > 0 && _scrollController.position.hasContentDimensions) {
        final fraction = (index / queueLength).clamp(0.0, 1.0);
        final targetOffset =
            (fraction * _scrollController.position.maxScrollExtent).clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            );
        _scrollController
            .animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              if (mounted) {
                final delayedCtx = _itemKeys[index]?.currentContext;
                if (delayedCtx != null && delayedCtx.mounted) {
                  Scrollable.ensureVisible(
                    delayedCtx,
                    alignment: 0.35,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                  );
                }
              }
            });
      }
    }
  }

  void _handleItemTap(int index) {
    _isUserScrolling = false;
    _userScrollTimer?.cancel();
    _currentIndexNotifier.value = index;
    _scrollToActiveIndex(index, userInitiated: true);
    widget.tts.seekToChunk(index).run();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      initialData: 0,
      stream: widget.tts.queueVersion,
      builder: (context, snapshot) {
        final queue = widget.tts.queue;

        if (queue.isEmpty) {
          return const AppLoadingView(
            label: 'Preparing sentences…',
            compact: true,
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              if (notification.dragDetails != null) {
                _isUserScrolling = true;
                _userScrollTimer?.cancel();
              }
            } else if (notification is ScrollEndNotification) {
              if (_isUserScrolling) {
                _userScrollTimer?.cancel();
                _userScrollTimer = Timer(const Duration(seconds: 3), () {
                  if (mounted) {
                    _isUserScrolling = false;
                  }
                });
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final chunk = queue[index];
              final isParagraphEnd =
                  chunk.isParagraphEnd && index < queue.length - 1;

              return RepaintBoundary(
                key: _keyForIndex(index),
                child: _SentenceQueueItem(
                  index: index,
                  chunk: chunk,
                  isParagraphEnd: isParagraphEnd,
                  currentIndexListenable: _currentIndexNotifier,
                  isPlayingListenable: _isPlayingNotifier,
                  onTap: () => _handleItemTap(index),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SentenceQueueItem extends StatefulWidget {
  const _SentenceQueueItem({
    required this.index,
    required this.chunk,
    required this.isParagraphEnd,
    required this.currentIndexListenable,
    required this.isPlayingListenable,
    required this.onTap,
  });

  final int index;
  final TtsChunk chunk;
  final bool isParagraphEnd;
  final ValueNotifier<int?> currentIndexListenable;
  final ValueNotifier<bool> isPlayingListenable;
  final VoidCallback onTap;

  @override
  State<_SentenceQueueItem> createState() => _SentenceQueueItemState();
}

class _SentenceQueueItemState extends State<_SentenceQueueItem> {
  late bool _isCurrent;

  @override
  void initState() {
    super.initState();
    _isCurrent = widget.currentIndexListenable.value == widget.index;
    widget.currentIndexListenable.addListener(_onIndexChanged);
  }

  @override
  void didUpdateWidget(covariant _SentenceQueueItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndexListenable != widget.currentIndexListenable) {
      oldWidget.currentIndexListenable.removeListener(_onIndexChanged);
      widget.currentIndexListenable.addListener(_onIndexChanged);
    }
    final isCurrent = widget.currentIndexListenable.value == widget.index;
    if (_isCurrent != isCurrent) {
      _isCurrent = isCurrent;
    }
  }

  @override
  void dispose() {
    widget.currentIndexListenable.removeListener(_onIndexChanged);
    super.dispose();
  }

  void _onIndexChanged() {
    final isCurrent = widget.currentIndexListenable.value == widget.index;
    if (_isCurrent != isCurrent) {
      setState(() {
        _isCurrent = isCurrent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: _isCurrent
                    ? Border.all(
                        color: scheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : Border.all(color: Colors.transparent),
              ),
              child: ListTile(
                tileColor: _isCurrent
                    ? scheme.primaryContainer.withValues(alpha: 0.35)
                    : Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: _isCurrent
                    ? ValueListenableBuilder<bool>(
                        valueListenable: widget.isPlayingListenable,
                        builder: (context, isPlaying, _) {
                          return LiveSpeechWaveform(
                            isPlaying: isPlaying,
                            barCount: 3,
                            height: 16,
                            width: 16,
                            color: scheme.primary,
                          );
                        },
                      )
                    : Icon(
                        LucideIcons.dot,
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        size: 16,
                      ),
                title: AppText(
                  widget.chunk.text,
                  variant: AppTextVariant.body,
                  fontWeight: _isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: _isCurrent
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.8),
                ),
                onTap: widget.onTap,
              ),
            ),
          ),
        ),
        if (widget.isParagraphEnd)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: scheme.outlineVariant.withValues(
                      alpha: 0.25,
                    ),
                    height: 1,
                    thickness: 0.8,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '¶',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: scheme.outlineVariant.withValues(
                      alpha: 0.25,
                    ),
                    height: 1,
                    thickness: 0.8,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
