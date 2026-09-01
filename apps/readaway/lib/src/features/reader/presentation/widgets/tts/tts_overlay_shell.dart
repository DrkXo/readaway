part of '../reader_widgets.dart';

/// Fluid gesture-driven TTS Sheet (max height 0.9 screen fraction).
class TtsOverlayShell extends StatefulWidget {
  const TtsOverlayShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<TtsOverlayShell> createState() => _TtsOverlayShellState();
}

class _TtsOverlayShellState extends State<TtsOverlayShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  static const double _miniPlayerHeight = 64.0;
  static const double _maxHeightFraction = 0.9;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    if (_animController.value > 0.5) {
      _animController.animateTo(0.0, curve: Curves.easeOutCubic);
    } else {
      _animController.animateTo(1.0, curve: Curves.easeOutCubic);
    }
  }

  void _closePlayer() {
    context.read<ReaderBloc>().add(const ReaderEvent.ttsClose());
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double totalRange) {
    if (totalRange <= 0) return;
    final delta = details.primaryDelta ?? 0;
    _animController.value -= (delta / totalRange);
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      _animController.animateTo(1.0, curve: Curves.easeOutCubic);
    } else if (velocity > 300) {
      _animController.animateTo(0.0, curve: Curves.easeOutCubic);
    } else {
      if (_animController.value > 0.5) {
        _animController.animateTo(1.0, curve: Curves.easeOutCubic);
      } else {
        _animController.animateTo(0.0, curve: Curves.easeOutCubic);
      }
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final tts = context.read<ReaderBloc>().ttsController;
    if (velocity < -200) {
      tts.skipToNextSentence();
    } else if (velocity > 200) {
      tts.skipToPreviousSentence();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final screenHeight = mediaQuery.size.height;
    final maxExpandedHeight = screenHeight * _maxHeightFraction;
    final bottomPadding = mediaQuery.padding.bottom;
    final minCollapsedHeight = _miniPlayerHeight + bottomPadding + 12.0;
    final totalDragRange = maxExpandedHeight - minCollapsedHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Primary Reader Page & Scaffold (full size)
        widget.child,

        // 2. Top Navigation Bar Overlay (Drawer Trigger & Reader Controls)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: BlocBuilder<ReaderBloc, ReaderState>(
            buildWhen: (prev, curr) => prev.hasDocument != curr.hasDocument,
            builder: (context, state) {
              if (!state.hasDocument) return const SizedBox.shrink();

              return SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(LucideIcons.menu),
                        tooltip: 'Contents',
                        onPressed: () {
                          context
                              .findAncestorStateOfType<ReaderPageState>()
                              ?.openDrawer();
                        },
                      ),
                      const Spacer(),
                      const ReaderCaptionActions.reFlowable(),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 3. Morphing Floating TTS Sheet
        BlocListener<ReaderBloc, ReaderState>(
          listenWhen: (prev, curr) =>
              prev.ttsActive != curr.ttsActive && curr.ttsActive,
          listener: (context, state) {
            _animController.value = 0.0;
          },
          child: BlocBuilder<ReaderBloc, ReaderState>(
            buildWhen: (prev, curr) => prev.ttsActive != curr.ttsActive,
            builder: (context, state) {
              if (!state.ttsActive) {
                return const SizedBox.shrink();
              }
              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final progress = _animController.value;

                  final currentHeight = lerpDouble(
                    minCollapsedHeight,
                    maxExpandedHeight,
                    progress,
                  )!;

                  return Positioned(
                    left: lerpDouble(12.0, 0.0, progress),
                    right: lerpDouble(12.0, 0.0, progress),
                    bottom: 0,
                    height: currentHeight,
                    child: Material(
                      elevation: 12,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(24),
                        bottom: Radius.circular(
                          lerpDouble(16.0, 0.0, progress)!,
                        ),
                      ),
                      color: Color.lerp(
                        theme.colorScheme.surfaceContainerHigh,
                        theme.colorScheme.surface,
                        progress,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: (1.0 - (progress * 3.0)).clamp(0.0, 1.0),
                            child: IgnorePointer(
                              ignoring: progress > 0.2,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _toggleSheet,
                                onVerticalDragUpdate: (details) =>
                                    _handleVerticalDragUpdate(
                                      details,
                                      totalDragRange,
                                    ),
                                onVerticalDragEnd: _handleVerticalDragEnd,
                                onHorizontalDragEnd: _handleHorizontalDragEnd,
                                child: TtsMiniPlayerBar(
                                  onClosePlayer: _closePlayer,
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: ((progress - 0.2) / 0.8).clamp(0.0, 1.0),
                            child: IgnorePointer(
                              ignoring: progress < 0.2,
                              child: TtsFullPlayerView(
                                onClose: _toggleSheet,
                                onClosePlayer: _closePlayer,
                                onDragUpdate: (details) =>
                                    _handleVerticalDragUpdate(
                                      details,
                                      totalDragRange,
                                    ),
                                onDragEnd: _handleVerticalDragEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
