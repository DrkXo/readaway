part of '../reader_widgets.dart';

class _PinButton extends StatelessWidget {
  const _PinButton({required this.pinned, required this.onTap});

  final bool pinned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        LucideIcons.pin,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: pinned ? 'Unpin panel' : 'Pin panel',
      onPressed: onTap,
    );
  }
}
