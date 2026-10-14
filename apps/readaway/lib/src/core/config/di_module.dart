import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:readaway/src/features/reader/presentation/controllers/reader_search_highlight_controller.dart';
import 'package:readaway_core/readaway_core.dart';

/// Registers external (non-app) services with the DI container.
@module
abstract class CoreModule {
  /// Shared pagination coordinator for reflowable documents.
  @lazySingleton
  PaginationCoordinator paginationCoordinator() => PaginationCoordinator();

  /// Transient holder for the in-document search match highlight.
  @lazySingleton
  ReaderSearchHighlightController readerSearchHighlightController() =>
      ReaderSearchHighlightController();

  /// Platform package info.
  @preResolve
  @singleton
  Future<PackageInfo> get packageInfo => PackageInfo.fromPlatform();
}
