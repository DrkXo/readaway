part of 'router.dart';

@lazySingleton
class AppRoutesGuards {
  bool get isAuthenticated => false;

  // ignore: unused_field
  final AppRoutes _appRoutes;

  AppRoutesGuards({
    required this._appRoutes,
  });
}
