part of '../core_widgets.dart';

/// Position of a [ReaderChromeBar].
enum ReaderChromePosition {
  top,
  bottom,
}

/// Generic immersive chrome bar for the reader.
///
/// Auto-hides on scroll, reveals on hover (desktop) or tap (touch), respects
/// safe areas, and uses a glassy surface derived from [AppColors]. This is a
/// generic primitive — it takes callbacks/children rather than depending on
/// [ReaderBloc], so it can be reused for any overlay chrome.
class ReaderChromeBar extends StatefulWidget {
  const ReaderChromeBar({
    super.key,
    required this.child,
    this.position = ReaderChromePosition.bottom,
    this.visible = true,
    this.onVisibilityChanged,
    this.height,
    this.glassOpacity = 0.85,
    this.padding,
  });

  final Widget child;
  final ReaderChromePosition position;
  final bool visible;
  final ValueChanged<bool>? onVisibilityChanged;
  final double? height;
  final double glassOpacity;
  final EdgeInsetsGeometry? padding;

  @override
  State<ReaderChromeBar> createState() => _ReaderChromeBarState();
}

class _ReaderChromeBarState extends State<ReaderChromeBar> {
  late bool _visible = widget.visible;

  @override
  void didUpdateWidget(covariant ReaderChromeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _visible = widget.visible;
    }
  }

  void _setVisible(bool value) {
    if (_visible == value) return;
    setState(() => _visible = value);
    widget.onVisibilityChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final isTop = widget.position == ReaderChromePosition.top;

    final content = AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: AnimatedSlide(
        offset: isTop
            ? Offset(0, _visible ? 0 : -1)
            : Offset(0, _visible ? 0 : 1),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !_visible,
          child: Container(
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: widget.glassOpacity),
              boxShadow: isTop ? appColors.shadowMd : appColors.shadowLg,
              borderRadius: isTop
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    )
                  : const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
            ),
            child: SafeArea(
              top: isTop,
              bottom: !isTop,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => _setVisible(true),
      onExit: (_) => _setVisible(false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _setVisible(!_visible),
        child: content,
      ),
    );
  }
}
