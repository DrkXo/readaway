part of '../core_widgets.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Settings',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: LucideIcons.settings,
      tooltip: tooltip,
      onPressed: onPressed ??
          () {
            appRouter.push(appRoutes.settings.path);
          },
    );
  }
}
