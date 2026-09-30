// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../core/routes/routes.dart';
import '../core/services/services.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/reader/presentation/bloc/reader_bloc.dart';
import '../features/reader/presentation/pages/reader_page.dart';
import '../features/settings/presentation/pages/settings_custom_fonts_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/voice_library_page.dart';
import '../features/settings/presentation/widgets/settings_sheet.dart';

part 'custom_routes.dart';

// =================================
// ==== Listenable for GoRouter ====
// =================================

class GoRouterListenable extends ChangeNotifier {
  GoRouterListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ==================================
// ==== PageTransition Animation ====
// ==================================

PageTransitionsTheme routerPageTransitionTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.iOS: const PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.linux: const PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.macOS: const PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.windows: const PredictiveBackPageTransitionsBuilder(),
  },
);

// ==================
// ==== Helpers ====
// ==================

BuildContext? get contextR => GetIt.I.get<AppRouter>().context;

GoRouter get appRouter => GetIt.I.get<AppRouter>().router;

// ==================
// ==== GoRouter ====
// ==================

@Singleton()
class AppRouter {
  final _log = AppLogger.instance.scope('AppRouter');

  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  final GlobalKey<NavigatorState> _settingsNavKey = GlobalKey<NavigatorState>(
    debugLabel: 'settings-sheet',
  );

  BuildContext? get context => _rootNavigatorKey.currentContext;

  GoRouter get router => _router;

  final AppRoutes _appRoutes;
  final FileOpenService _fileOpenService;

  StreamSubscription<IncomingDocument>? _fileOpenSubscription;

  AppRouter({
    required AppRoutes appRoutes,
    required FileOpenService fileOpenService,
  }) : _appRoutes = appRoutes,
       _fileOpenService = fileOpenService {
    _fileOpenSubscription = _fileOpenService.incomingDocuments.listen(
      _navigateToDocument,
    );
  }

  void _navigateToDocument(IncomingDocument doc) {
    final externalSuffix = doc.fromExternalLaunch ? '&external=true' : '';
    final route =
        '${_appRoutes.reader.path}?path=${Uri.encodeComponent(doc.path)}&fileName=${Uri.encodeComponent(doc.fileName)}$externalSuffix';
    _log.i('Navigating to opened document: $route');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // matchedLocation strips query params, so compare against the path only.
      if (_router.state.matchedLocation == _appRoutes.reader.path) return;
      if (doc.fromExternalLaunch) {
        _router.go(route);
      } else {
        _router.push(route);
      }
    });
  }

  @disposeMethod
  void dispose() {
    _fileOpenSubscription?.cancel();
    _router.dispose();
  }

  late final _router = GoRouter(
    initialLocation: _appRoutes.library.path,
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    routes: [
      // 1. Top-Level Library Page (Outside TTS Overlay Shell)
      GoRoute(
        name: _appRoutes.library.name,
        path: _appRoutes.library.path,
        builder: (context, state) => const LibraryPage(),
      ),

      GoRoute(
        name: _appRoutes.reader.name,
        path: _appRoutes.reader.path,
        onExit: (context, state) {
          final isExternal = state.uri.queryParameters['external'] == 'true';
          if (isExternal && !kIsWeb) {
            if (Platform.isAndroid ||
                Platform.isWindows ||
                Platform.isLinux ||
                Platform.isMacOS) {
              SystemNavigator.pop();
              return false;
            }
          }
          return true;
        },
        builder: (context, state) {
          return BlocProvider<ReaderBloc>(
            create: (_) => GetIt.I.get<ReaderBloc>(),
            child: ReaderPage.fromRoute(state),
          );
        },
      ),

      // Global Modal overlaid on top of the router.
      //
      // The settings sheet is a ShellRoute hosting a nested navigator with a
      // stable key ('settings-modal'). Sub-pages (voice library, custom fonts)
      // are child routes that push within the sheet's nested navigator, keeping
      // the sheet open and bypassing Flutter's _ModalScope caching.
      ShellRoute(
        navigatorKey: _settingsNavKey,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state, child) => ModalPage(
          key: const ValueKey('settings-modal'),
          isScrollControlled: true,
          showDragHandle: false,
          builder: (context) => SettingsSheet(child: child),
        ),
        routes: [
          GoRoute(
            name: _appRoutes.settings.name,
            path: _appRoutes.settings.path,
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final initialTab = switch (tabParam) {
                'layout' => SettingsTab.layout,
                'behavior' => SettingsTab.behavior,
                'appearance' => SettingsTab.appearance,
                'tts' => SettingsTab.tts,
                _ => SettingsTab.font,
              };
              final documentPath = state.uri.queryParameters['documentPath'];

              return SettingsPage(
                initialTab: initialTab,
                documentPath: documentPath,
              );
            },
            routes: [
              GoRoute(
                name: _appRoutes.settingsVoices.name,
                path: _appRoutes.settingsVoices.lastSegment,
                builder: (context, state) => const VoiceLibraryPage(),
              ),
              GoRoute(
                name: _appRoutes.settingsFonts.name,
                path: _appRoutes.settingsFonts.lastSegment,
                builder: (context, state) => const SettingsCustomFontsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
