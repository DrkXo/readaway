part of '../core_widgets.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MorphIconButton(
      icon: Icons.tune_rounded,
      hoverIcon: Icons.settings_rounded,
      tooltip: 'Reader options',
      onTap: () {
        appRouter.push(appRoutes.settings.path);
      },
    );
  }
}

/// Compact icon button whose glyph morphs into [hoverIcon] on hover.
class MorphIconButton extends StatefulWidget {
  const MorphIconButton({
    super.key,
    required this.icon,
    required this.hoverIcon,
    required this.tooltip,
    this.onTap,
    this.size = 18,
    this.color,
  });

  final IconData icon;
  final IconData hoverIcon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  @override
  State<MorphIconButton> createState() => _MorphIconButtonState();
}

class _MorphIconButtonState extends State<MorphIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IconButton(
        onPressed: widget.onTap,
        tooltip: widget.tooltip,
        icon: AnimatedMorphIcon(
          icon: _hovered ? widget.hoverIcon : widget.icon,
          size: widget.size,
        ),
        color: widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
