import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

/// Registers external (non-app) services with the DI container.
@module
abstract class CoreModule {
  /// Shared pagination coordinator for reflowable documents.
  @lazySingleton
  PaginationCoordinator paginationCoordinator() => PaginationCoordinator();
}
