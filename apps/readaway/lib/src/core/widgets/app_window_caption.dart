part of 'core_widgets.dart';

/// Custom titlebar for the frameless desktop window. All window operations
/// go through [WindowService]; maximize state comes from its stream.
class AppWindowCaption extends StatelessWidget {
  const AppWindowCaption({super.key, required this.service, this.actions});

  final WindowService service;

  /// Optional app-specific actions shown before the window controls
  /// (e.g. reader operations while a document is open).
  final Widget? actions;

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
                    ?actions,
                    SettingsButton(),
                    MorphIconButton(
                      icon: Icons.remove_rounded,
                      hoverIcon: Icons.keyboard_arrow_down_rounded,
                      tooltip: 'Minimize',
                      onTap: service.minimize,
                    ),
                    _MaximizeCaptionButton(service: service),
                    MorphIconButton(
                      icon: Icons.close_rounded,
                      hoverIcon: Icons.cancel_rounded,
                      tooltip: 'Close',
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
        return MorphIconButton(
          icon: isMaximized
              ? Icons.filter_none_rounded
              : Icons.crop_square_rounded,
          hoverIcon: isMaximized
              ? Icons.close_fullscreen_rounded
              : Icons.open_in_full_rounded,
          tooltip: isMaximized ? 'Restore' : 'Maximize',
          onTap: () => isMaximized
              ? widget.service.unmaximize()
              : widget.service.maximize(),
        );
      },
    );
  }
}
