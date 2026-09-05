import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../flavors.dart';
import 'core/services/services.dart';
import 'features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'router/router.dart';

class ReadAway extends StatefulWidget {
  const ReadAway({super.key});

  @override
  State<ReadAway> createState() => _ReadAwayState();
}

class _ReadAwayState extends State<ReadAway> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = GetIt.I.get<AppRouter>().router;
    final themeService = GetIt.I.get<ThemeService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I.get<SettingsBloc>()..loadPrefs(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return StreamBuilder<ThemeMode>(
            stream: themeService.themeChanges,
            initialData: themeService.currentThemeMode,
            builder: (context, snapshot) {
              final themeMode = snapshot.data ?? ThemeMode.system;

              return MaterialApp.router(
                title: F.title,
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: themeService.getLightTheme(),
                darkTheme: themeService.getDarkTheme(),
                routerConfig: router,
                builder: (context, child) {
                  return child ?? const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }
}
