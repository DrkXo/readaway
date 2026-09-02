part of '../core_widgets.dart';

class PinButton extends StatelessWidget {
  const PinButton({super.key, required this.pinned, required this.onTap});

  final bool pinned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: LucideIcons.pin,
      tooltip: pinned ? 'Unpin panel' : 'Pin panel',
      onPressed: onTap,
      size: AppIconButtonSize.small,
      selected: pinned,
    );
  }
}
