part of '../core_widgets.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        appRouter.push(appRoutes.settings.path);
      },
      icon: Icon(Icons.settings),
    );
  }
}
