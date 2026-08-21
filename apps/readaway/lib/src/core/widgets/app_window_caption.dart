part of 'core_widgets.dart';

/// Custom titlebar for the frameless desktop window. All window operations
/// go through [WindowService]; maximize state comes from its stream.
class AppWindowCaption extends StatelessWidget {
  const AppWindowCaption({super.key, required this.service});

  final WindowService service;

  static const double height = 40;

  Future<void> _toggleMaximize() async {
    if (await service.isMaximized()) {
      await service.unmaximize();
    } else {
      await service.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRect(
      child:
          SizedBox(
            height: height,
            child: Material(
              color: scheme.surface,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => service.startDragging(),
                onDoubleTap: _toggleMaximize,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: StreamBuilder<String>(
                        stream: service.windowTitleChanges,
                        initialData: service.currentTitle,
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? F.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    _CaptionButton(
                      icon: Icons.remove_rounded,
                      hoverIcon: Icons.keyboard_arrow_down_rounded,
                      onTap: service.minimize,
                    ),
                    _MaximizeCaptionButton(service: service),
                    _CaptionButton(
                      icon: Icons.close_rounded,
                      hoverIcon: Icons.cancel_rounded,
                      onTap: service.close,
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slide(
            begin: const Offset(0, -1),
            end: Offset.zero,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.onTap,
    this.hoverIcon,
  });

  final IconData icon;
  final IconData? hoverIcon;
  final Future<void> Function() onTap;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IconButton(
        onPressed: widget.onTap,
        icon: AnimatedMorphIcon(
          icon: _hovered && widget.hoverIcon != null
              ? widget.hoverIcon!
              : widget.icon,
          size: 18,
        ),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _MaximizeCaptionButton extends StatefulWidget {
  const _MaximizeCaptionButton({required this.service});

  final WindowService service;

  @override
  State<_MaximizeCaptionButton> createState() => _MaximizeCaptionButtonState();
}

class _MaximizeCaptionButtonState extends State<_MaximizeCaptionButton> {
  @override
  void initState() {
    super.initState();
    // Seed the stream with the actual current state.
    widget.service.isMaximized();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.service.windowMaximizeChanges,
      initialData: false,
      builder: (context, snapshot) {
        final isMaximized = snapshot.data ?? false;
        return _CaptionButton(
          icon: isMaximized
              ? Icons.filter_none_rounded
              : Icons.crop_square_rounded,
          hoverIcon: isMaximized
              ? Icons.close_fullscreen_rounded
              : Icons.open_in_full_rounded,
          onTap: () => isMaximized
              ? widget.service.unmaximize()
              : widget.service.maximize(),
        );
      },
    );
  }
}
