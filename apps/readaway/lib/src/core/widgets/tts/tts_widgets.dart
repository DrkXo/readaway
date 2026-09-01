part of '../core_widgets.dart';

/// Fluid gesture-driven TTS Sheet (max height 0.9 screen fraction).
/// - Drag UP / DOWN on mini bar or drag handle -> continuous 1:1 finger tracking
/// - Release drag -> smooth snap to either open (0.9 height) or closed (collapsed bar)
/// - Tap mini player -> toggle open / close
/// - Swipe LEFT / RIGHT on mini player -> sentence skipping
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
  bool _isPlaybackActive = true;

  // Configuration Heights
  static const double _miniPlayerHeight = 64.0;
  static const double _maxHeightFraction = 0.9; // 90% screen height limit

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

  void _stopPlaybackAndClose() {
    setState(() {
      _isPlaybackActive = false;
    });
    _animController.value = 0.0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double totalRange) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Height calculations
    final screenHeight = mediaQuery.size.height;
    final maxExpandedHeight = screenHeight * _maxHeightFraction;
    final bottomPadding = mediaQuery.padding.bottom;
    final minCollapsedHeight = _miniPlayerHeight + bottomPadding + 12.0;
    final totalDragRange = maxExpandedHeight - minCollapsedHeight;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Reader View Content
          Positioned.fill(child: widget.child),

          // 1.5 Reader-specific caption content (menu button + caption actions)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: BlocBuilder<ReaderBloc, ReaderState>(
              buildWhen: (prev, curr) => prev.hasDocument != curr.hasDocument,
              builder: (context, state) {
                if (!state.hasDocument) {
                  return const SizedBox.shrink();
                }
                return SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        MorphIconButton(
                          icon: LucideIcons.menu,
                          hoverIcon: LucideIcons.panelLeftOpen,
                          tooltip: 'Contents',
                          onTap: () => ReaderPage
                              .scaffoldKey
                              .currentState
                              ?.openDrawer(),
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

          // 2. Continuous Drag & Morph Overlay
          if (_isPlaybackActive)
            AnimatedBuilder(
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
                        // Mini Player Bar Content (Active when collapsed)
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
                              onHorizontalDragEnd: (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity < -200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Skipped to Next Sentence'),
                                      duration: Duration(milliseconds: 600),
                                    ),
                                  );
                                } else if (velocity > 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Skipped to Previous Sentence',
                                      ),
                                      duration: Duration(milliseconds: 600),
                                    ),
                                  );
                                }
                              },
                              child: TtsMiniPlayerBar(
                                onClosePlayer: _stopPlaybackAndClose,
                              ),
                            ),
                          ),
                        ),

                        // Full Player View (Active when expanded)
                        Opacity(
                          opacity: ((progress - 0.2) / 0.8).clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: progress < 0.2,
                            child: TtsFullPlayerView(
                              onClose: _toggleSheet,
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
            ),
        ],
      ),
    );
  }
}

/// Mini Player Bar widget with play/pause and close controls
class TtsMiniPlayerBar extends StatelessWidget {
  const TtsMiniPlayerBar({
    required this.onClosePlayer,
    super.key,
  });

  final VoidCallback onClosePlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TtsMiniPlayerBar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Drag ↑ / ↓ anywhere • Tap bar to open • Swipe ←/→ skip',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Media Play/Pause Button
          IconButton(
            icon: const Icon(Icons.pause_circle_filled),
            onPressed: () {},
          ),
          // Close Player Button
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close Player',
            onPressed: onClosePlayer,
          ),
        ],
      ),
    );
  }
}

/// Full Player View with scrollable Queue top area & bottom-anchored controls
class TtsFullPlayerView extends StatelessWidget {
  const TtsFullPlayerView({
    required this.onClose,
    required this.onDragUpdate,
    required this.onDragEnd,
    super.key,
  });

  final VoidCallback onClose;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 1. Top Drag Handle & Title Bar (Fixed at top)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: onClose,
                    ),
                    const Expanded(
                      child: Text(
                        'Up Next Queue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const Divider(height: 1),
              ],
            ),
          ),

          // 2. Scrollable Playlist / Queue Content
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        title: Text('Sentence block item #${index + 1}'),
                        subtitle: const Text('0:15 • Reading segment'),
                        trailing: IconButton(
                          icon: const Icon(Icons.drag_handle, size: 20),
                          onPressed: () {},
                        ),
                      );
                    },
                    childCount: 30,
                  ),
                ),
              ],
            ),
          ),

          // 3. Anchored Bottom Media Controls Section
          _BottomPlayerControls(
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
          ),
        ],
      ),
    );
  }
}

/// Bottom-anchored controls view with optional gesture handle area
class _BottomPlayerControls extends StatelessWidget {
  const _BottomPlayerControls({
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.multitrack_audio, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now Playing Chapter 1',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ReadAway Reader',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {},
                ),
                IconButton(
                  iconSize: 52,
                  icon: const Icon(Icons.pause_circle_filled),
                  onPressed: () {},
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
