part of '../core_widgets.dart';

/// Caption buttons (minimize, maximize/restore, close) for frameless desktop windows.
///
/// Automatically hides itself on non-desktop platforms.
class WindowCaptionControls extends StatelessWidget {
  const WindowCaptionControls({
    super.key,
    this.service,
    this.buttonWidth = 44.0,
  });

  final WindowService? service;
  final double buttonWidth;

  @override
  Widget build(BuildContext context) {
    final windowService = service ?? GetIt.I<WindowService>();
    if (!windowService.isDesktop) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WindowCaptionButton(
          width: buttonWidth,
          icon: LucideIcons.minus,
          tooltip: 'Minimize',
          onPressed: windowService.minimize,
        ),
        _WindowMaximizeCaptionButton(
          service: windowService,
          width: buttonWidth,
        ),
        _WindowCaptionButton(
          width: buttonWidth,
          icon: LucideIcons.x,
          tooltip: 'Close',
          isClose: true,
          onPressed: windowService.close,
        ),
      ],
    );
  }
}

class _WindowMaximizeCaptionButton extends StatefulWidget {
  const _WindowMaximizeCaptionButton({
    required this.service,
    required this.width,
  });

  final WindowService service;
  final double width;

  @override
  State<_WindowMaximizeCaptionButton> createState() =>
      _WindowMaximizeCaptionButtonState();
}

class _WindowMaximizeCaptionButtonState
    extends State<_WindowMaximizeCaptionButton> {
  @override
  void initState() {
    super.initState();
    widget.service.isMaximized();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.service.windowMaximizeChanges,
      initialData: false,
      builder: (context, snapshot) {
        final isMaximized = snapshot.data ?? false;
        return _WindowCaptionButton(
          width: widget.width,
          icon: isMaximized ? LucideIcons.copy : LucideIcons.square,
          iconSize: isMaximized ? 13.0 : 14.0,
          tooltip: isMaximized ? 'Restore' : 'Maximize',
          onPressed: widget.service.toggleMaximize,
        );
      },
    );
  }
}

class _WindowCaptionButton extends StatefulWidget {
  const _WindowCaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.width = 44.0,
    this.iconSize = 14.0,
    this.isClose = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double width;
  final double iconSize;
  final bool isClose;

  @override
  State<_WindowCaptionButton> createState() => _WindowCaptionButtonState();
}

class _WindowCaptionButtonState extends State<_WindowCaptionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color backgroundColor;
    Color iconColor;

    if (widget.isClose) {
      if (_pressed) {
        backgroundColor = const Color(0xFFC42B1C);
        iconColor = Colors.white;
      } else if (_hovered) {
        backgroundColor = const Color(0xFFE81123);
        iconColor = Colors.white;
      } else {
        backgroundColor = Colors.transparent;
        iconColor = scheme.onSurfaceVariant;
      }
    } else {
      if (_pressed) {
        backgroundColor = scheme.onSurface.withValues(alpha: 0.14);
        iconColor = scheme.onSurface;
      } else if (_hovered) {
        backgroundColor = scheme.onSurface.withValues(alpha: 0.08);
        iconColor = scheme.onSurface;
      } else {
        backgroundColor = Colors.transparent;
        iconColor = scheme.onSurfaceVariant;
      }
    }

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.width,
            alignment: Alignment.center,
            color: backgroundColor,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
