import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway/src/features/library/presentation/pages/library_page.dart';
import 'package:readaway/src/features/reader/presentation/pages/reader_page.dart';
import 'package:readaway/src/features/settings/presentation/pages/settings_page.dart';

import '../core/routes/routes.dart';
import '../core/services/services.dart';
import '../core/widgets/core_widgets.dart';

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
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNav(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: _appRoutes.library.name,
                path: _appRoutes.library.path,
                builder: (context, state) => LibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: _appRoutes.settings.name,
                path: _appRoutes.settings.path,
                builder: (context, state) => SettingsPage(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        name: _appRoutes.reader.name,
        path: _appRoutes.reader.path,
        builder: (context, state) => ReaderPage.fromRoute(state),
      ),
    ],
  );
}
