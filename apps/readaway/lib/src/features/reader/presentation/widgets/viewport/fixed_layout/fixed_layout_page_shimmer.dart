import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/theme/theme.dart';

/// An elegant, theme-aware shimmer skeleton placeholder displayed while a
/// fixed-layout or comic/PDF page is being decoded.
///
/// Preserves the exact aspect ratio of the page to eliminate layout jumping
/// and jarring flashes during rapid scrolling or page turns.
class FixedLayoutPageShimmer extends StatefulWidget {
  const FixedLayoutPageShimmer({
    super.key,
    required this.pageIndex,
    this.aspectRatio,
  });

  final int pageIndex;
  final double? aspectRatio;

  @override
  State<FixedLayoutPageShimmer> createState() => _FixedLayoutPageShimmerState();
}

class _FixedLayoutPageShimmerState extends State<FixedLayoutPageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? appColors.readerBackground.withValues(alpha: 0.6)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);

    final ratio = (widget.aspectRatio != null && widget.aspectRatio! > 0)
        ? widget.aspectRatio!
        : 0.707; // Standard A4 / comic aspect ratio default

    return Center(
      child: AspectRatio(
        aspectRatio: ratio,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                  width: 1.0,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    (_controller.value - 0.3).clamp(0.0, 1.0),
                    _controller.value.clamp(0.0, 1.0),
                    (_controller.value + 0.3).clamp(0.0, 1.0),
                  ],
                  colors: [
                    baseColor,
                    highlightColor,
                    baseColor,
                  ],
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.pageIndex + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
