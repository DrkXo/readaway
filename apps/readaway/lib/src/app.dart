import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'core/theme/theme.dart';
import 'features/settings/domain/models/reader_preferences.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'router/router.dart';

import '../flavors.dart';
import 'core/services/services.dart';
import 'features/reader/presentation/bloc/reader_bloc.dart';

class ReadAway extends StatefulWidget {
  const ReadAway({super.key});

  @override
  State<ReadAway> createState() => _ReadAwayState();
}

class _ReadAwayState extends State<ReadAway> {
  @override
  void initState() {
    appLifecycleManager.initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final router = GetIt.I.get<AppRouter>().router;
    final appTheme = GetIt.I.get<AppTheme>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I.get<ReaderBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I.get<SettingsBloc>()..loadPrefs(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final themeMode = settingsState.globalReaderPrefs.themeMode
              .toThemeMode();

          return MaterialApp.router(
            title: F.title,
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: appTheme.lightTheme,
            darkTheme: appTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

extension _ReaderThemeModeX on ReaderThemeMode {
  ThemeMode toThemeMode() => switch (this) {
    ReaderThemeMode.light => ThemeMode.light,
    ReaderThemeMode.dark => ThemeMode.dark,
    ReaderThemeMode.system => ThemeMode.system,
  };
}
