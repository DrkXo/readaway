part of '../core_widgets.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: LucideIcons.settings,
      tooltip: 'Reader options',
      onPressed: () {
        appRouter.push(appRoutes.settings.path);
      },
    );
  }
}
