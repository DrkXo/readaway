import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../core/routes/routes.dart';
import '../core/services/services.dart';
import '../core/widgets/core_widgets.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/reader/reader.dart';
import '../features/settings/presentation/pages/custom_fonts_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';

part 'custom_routes.dart';
part 'guards.dart';

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
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  BuildContext? get context => _rootNavigatorKey.currentContext;

  GoRouter get router => _router;

  // ignore: unused_field
  final AppRoutesGuards _appRoutesGuards;
  // ignore: unused_field
  final LoggingService _logger;
  final AppRoutes _appRoutes;

  AppRouter({
    required this._appRoutesGuards,
    required this._logger,
    required this._appRoutes,
  });

  @disposeMethod
  void dispose() {
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

      // 2. Reader Shell Route carrying the TTS Overlay ONLY for Reader
      ShellRoute(
        builder: (context, state, child) {
          return TtsOverlayShell(child: child);
        },
        routes: [
          GoRoute(
            name: _appRoutes.reader.name,
            path: _appRoutes.reader.path,
            builder: (context, state) {
              return ReaderPage.fromRoute(state);
            },
          ),
        ],
      ),

      // Global Modals overlaid on top of the router
      GoRoute(
        name: _appRoutes.settings.name,
        path: _appRoutes.settings.path,
        pageBuilder: (context, state) {
          return ModalPage(
            key: state.pageKey,
            isScrollControlled: true,
            showDragHandle: false,
            builder: (context) => const SettingsPage(),
          );
        },
        routes: [
          GoRoute(
            name: _appRoutes.customFonts.name,
            path: _appRoutes.customFonts.path,
            pageBuilder: (context, state) {
              return ModalPage(
                key: state.pageKey,
                isScrollControlled: true,
                showDragHandle: false,
                builder: (context) => const CustomFontsPage(),
              );
            },
          ),
        ],
      ),

      // Reader Dictionary Lookup Sheet
      GoRoute(
        name: _appRoutes.readerLookup.name,
        path: _appRoutes.readerLookup.path,
        pageBuilder: (context, state) {
          return ModalPage(
            key: state.pageKey,
            enableDrag: true,
            showDragHandle: false,
            builder: (context) => ReaderLookupSheet(
              request: state.extra! as ReaderLookupRequest,
            ),
          );
        },
      ),
    ],
  );
}
