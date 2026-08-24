part of '../reader_widgets.dart';

/// Single-row compact control bar: page nav, seek slider, progress and
/// outline toggle. Hidden by default; revealed on hover (desktop) or by
/// tapping its strip (touch).
class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    super.key,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSeekToPage,
    this.onOutlineTap,
  });

  /// Navigates to the previous page.
  final VoidCallback onPreviousPage;

  /// Navigates to the next page.
  final VoidCallback onNextPage;

  /// Seeks to a specific page index.
  final ValueChanged<int> onSeekToPage;

  /// When set, the outline button toggles the desktop side panel instead
  /// of opening the mobile drawer.
  final VoidCallback? onOutlineTap;

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  bool _visible = false;
  bool _isDragging = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _visible = true),
        onExit: (_) => setState(() => _visible = false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => setState(() => _visible = !_visible),
          child: SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                ignoring: !_visible,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedSlide(
                    offset: _visible ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 150),
                    child: _buildContent(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.htmlPages != curr.htmlPages ||
          prev.pageImages != curr.pageImages,
      builder: (context, state) {
        if (!state.hasDocument) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final page = _isDragging ? _dragValue! : state.currentPage.toDouble();
        final percent = state.pageCount > 0
            ? ((page / (state.pageCount - 1)) * 100).round()
            : 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.85),
            boxShadow: context.appColors.shadowMd,
          ),
          child: Row(
            children: [
              _buildNavButton(
                enabled: state.currentPage > 0,
                icon: LucideIcons.chevronLeft,
                tooltip: 'Previous page',
                onTap: widget.onPreviousPage,
              ),
              Expanded(child: _buildSlider(context, state)),
              _buildNavButton(
                enabled: state.currentPage < state.pageCount - 1,
                icon: LucideIcons.chevronRight,
                tooltip: 'Next page',
                onTap: widget.onNextPage,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.currentPage + 1} / ${state.pageCount}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                onPressed:
                    widget.onOutlineTap ??
                    () => Scaffold.of(context).openDrawer(),
                icon: const Icon(LucideIcons.moreVertical, size: 20),
                color: scheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                tooltip: 'Outline',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlider(BuildContext context, ReaderState state) {
    final scheme = Theme.of(context).colorScheme;
    final page = _isDragging ? _dragValue! : state.currentPage.toDouble();
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.08),
      ),
      child: Slider(
        value: page
            .clamp(0, (state.pageCount - 1).clamp(0, double.infinity))
            .toDouble(),
        min: 0,
        max: (state.pageCount - 1).clamp(1, double.infinity).toDouble(),
        onChangeStart: (v) {
          setState(() {
            _isDragging = true;
            _dragValue = v;
          });
        },
        onChanged: (v) {
          setState(() => _dragValue = v);
        },
        onChangeEnd: (v) {
          final target = v.round();
          setState(() {
            _isDragging = false;
            _dragValue = null;
          });
          widget.onSeekToPage(target);
        },
      ),
    );
  }

  Widget _buildNavButton({
    required bool enabled,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 22),
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
    );
  }
}
