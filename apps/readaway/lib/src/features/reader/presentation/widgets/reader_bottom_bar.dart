import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/reader_bloc.dart';
import 'reader_overlay_controller.dart';

class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    super.key,
    required this.pageController,
    required this.controller,
    this.onSettingsTap,
  });

  final PageController pageController;
  final ReaderOverlayController controller;
  final VoidCallback? onSettingsTap;

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageScroll);
  }

  @override
  void didUpdateWidget(ReaderBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController.removeListener(_onPageScroll);
      widget.pageController.addListener(_onPageScroll);
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageScroll);
    super.dispose();
  }

  void _onPageScroll() {
    if (_isDragging) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: widget.controller.barsVisible
          ? _buildContent(context)
          : const SizedBox.shrink(),
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

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.85),
              boxShadow: context.appColors.shadowMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSliderRow(context, state, scheme),
                _buildInfoRow(context, state, scheme, percent),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderRow(
    BuildContext context,
    ReaderState state,
    ColorScheme scheme,
  ) {
    final page = _isDragging ? _dragValue! : state.currentPage.toDouble();
    return Row(
      children: [
        _buildNavButton(
          enabled: state.currentPage > 0,
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous page',
          onTap: () => widget.pageController.previousPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        ),
        Expanded(
          child: SliderTheme(
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
                widget.pageController.animateToPage(
                  target,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        ),
        _buildNavButton(
          enabled: state.currentPage < state.pageCount - 1,
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next page',
          onTap: () => widget.pageController.nextPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        ),
      ],
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
      tooltip: tooltip,
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ReaderState state,
    ColorScheme scheme,
    int percent,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${state.currentPage + 1} / ${state.pageCount}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (widget.onSettingsTap != null)
          IconButton(
            onPressed: widget.onSettingsTap,
            icon: const Icon(Icons.tune_rounded, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            tooltip: 'Reader settings',
          ),
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
