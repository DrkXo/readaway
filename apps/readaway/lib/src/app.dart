import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../flavors.dart';
import 'core/services/services.dart';
import 'core/widgets/core_widgets.dart';
import 'features/reader/reader.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'router/router.dart';

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
    final themeService = GetIt.I.get<ThemeService>();

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
                  final content = child ?? const SizedBox.shrink();
                  if (!GetIt.I<WindowService>().isDesktop) return content;
                  // Overlay above the Navigator so widgets in the caption
                  // (tooltips, popovers) have an ancestor to render into.
                  return Overlay(
                    initialEntries: [
                      OverlayEntry(
                        builder: (_) => Column(
                          children: [
                            AppWindowCaption(
                              service: GetIt.I<WindowService>(),
                              leading: BlocBuilder<ReaderBloc, ReaderState>(
                                buildWhen: (prev, curr) =>
                                    prev.hasDocument != curr.hasDocument,
                                builder: (context, state) => state.hasDocument
                                    ? MorphIconButton(
                                        icon: LucideIcons.menu,
                                        hoverIcon: LucideIcons.panelLeftOpen,
                                        tooltip: 'Contents',
                                        onTap: () => ReaderPage
                                            .scaffoldKey
                                            .currentState
                                            ?.openDrawer(),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              actions: BlocBuilder<ReaderBloc, ReaderState>(
                                buildWhen: (prev, curr) =>
                                    prev.hasDocument != curr.hasDocument,
                                builder: (context, state) => state.hasDocument
                                    ? const ReaderCaptionActions.reFlowable()
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Expanded(child: content),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
