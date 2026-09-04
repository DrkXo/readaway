// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/reader/domain/services/document_parser.dart' as _i428;
import '../../features/reader/presentation/bloc/reader_bloc.dart' as _i523;
import '../../features/settings/presentation/bloc/settings/settings_bloc.dart'
    as _i228;
import '../../router/router.dart' as _i295;
import '../routes/routes.dart' as _i494;
import '../services/html_document_parser.dart' as _i865;
import '../services/services.dart' as _i264;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i494.AppRoutes>(() => _i494.AppRoutes());
    gh.singleton<_i264.AppLifecycleManager>(() => _i264.AppLifecycleManager());
    await gh.singletonAsync<_i264.LoggingService>(() {
      final i = _i264.LoggingService();
      return i.init().then((_) => i);
    }, preResolve: true);
    await gh.singletonAsync<_i264.PackageInfoService>(() {
      final i = _i264.PackageInfoService();
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.singleton<_i264.WakelockService>(() => _i264.WakelockService());
    await gh.singletonAsync<_i264.WindowService>(
      () {
        final i = _i264.WindowService();
        return i.initialize().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i264.AppPathService>(() => _i264.AppPathService());
    gh.lazySingleton<_i264.TextChunker>(() => _i264.TextChunker());
    gh.factory<_i264.HiveConfigService>(
      () => _i264.HiveConfigService(gh<_i264.AppPathService>()),
    );
    gh.lazySingleton<_i428.DocumentParser<String>>(
      () => const _i865.HtmlDocumentParser(),
    );
    await gh.singletonAsync<_i264.NotificationService>(
      () {
        final i = _i264.NotificationService(gh<_i264.PackageInfoService>());
        return i.initialize().then((_) => i);
      },
      dependsOn: [_i264.PackageInfoService],
      preResolve: true,
    );
    await gh.lazySingletonAsync<_i264.HttpService>(() {
      final i = _i264.HttpService(
        logger: gh<_i264.LoggingService>(),
        pathService: gh<_i264.AppPathService>(),
      );
      return i.initialize().then((_) => i);
    }, preResolve: true);
    gh.singleton<_i264.IsolateService>(
      () => _i264.IsolateService(loggingService: gh<_i264.LoggingService>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i295.AppRoutesGuards>(
      () => _i295.AppRoutesGuards(appRoutes: gh<_i494.AppRoutes>()),
    );
    gh.lazySingleton<_i264.TtsChunkingService>(
      () => _i264.TtsChunkingService(gh<_i264.IsolateService>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i264.SherpaTtsModelCatalogService>(
      () => _i264.SherpaTtsModelCatalogService(
        httpService: gh<_i264.HttpService>(),
      ),
    );
    await gh.singletonAsync<_i264.JustAudioService>(
      () {
        final i = _i264.JustAudioService(
          gh<_i264.PackageInfoService>(),
          gh<_i264.NotificationService>(),
        );
        return i.init().then((_) => i);
      },
      dependsOn: [
        _i264.LoggingService,
        _i264.NotificationService,
        _i264.PackageInfoService,
      ],
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i264.LookupService>(
      () => _i264.LookupService(gh<_i264.HttpService>()),
    );
    gh.singleton<_i295.AppRouter>(
      () => _i295.AppRouter(
        appRoutesGuards: gh<_i295.AppRoutesGuards>(),
        logger: gh<_i264.LoggingService>(),
        appRoutes: gh<_i494.AppRoutes>(),
      ),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i264.AppStorageService>(
      () {
        final i = _i264.AppStorageService(
          config: gh<_i264.HiveConfigService>(),
          isolateService: gh<_i264.IsolateService>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i264.SherpaTtsModelDownloaderService>(
      () => _i264.SherpaTtsModelDownloaderService(
        client: gh<_i264.HttpService>(),
        catalog: gh<_i264.SherpaTtsModelCatalogService>(),
        pathService: gh<_i264.AppPathService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i264.SherpaOnnxTtsService>(
      () {
        final i = _i264.SherpaOnnxTtsService(
          downloader: gh<_i264.SherpaTtsModelDownloaderService>(),
          sherpaTtsModelCatalog: gh<_i264.SherpaTtsModelCatalogService>(),
          isolateService: gh<_i264.IsolateService>(),
          pathService: gh<_i264.AppPathService>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i264.SettingsService>(
      () {
        final i = _i264.SettingsService(storage: gh<_i264.AppStorageService>());
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i264.MuPdfService>(
      () => _i264.MuPdfService(
        isolateService: gh<_i264.IsolateService>(),
        loggingService: gh<_i264.LoggingService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i264.TtsControllerService>(
      () => _i264.TtsControllerService(
        gh<_i264.SherpaOnnxTtsService>(),
        gh<_i264.JustAudioService>(),
        gh<_i264.TtsChunkingService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i228.SettingsBloc>(
      () => _i228.SettingsBloc(
        storage: gh<_i264.AppStorageService>(),
        settingsService: gh<_i264.SettingsService>(),
        ttsService: gh<_i264.SherpaOnnxTtsService>(),
      ),
    );
    await gh.singletonAsync<_i264.ThemeService>(
      () {
        final i = _i264.ThemeService(settings: gh<_i264.SettingsService>());
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i523.ReaderBloc>(
      () => _i523.ReaderBloc(
        windowService: gh<_i264.WindowService>(),
        muPdfService: gh<_i264.MuPdfService>(),
        ttsController: gh<_i264.TtsControllerService>(),
        settingsBloc: gh<_i228.SettingsBloc>(),
        documentParser: gh<_i428.DocumentParser<String>>(),
        notificationService: gh<_i264.NotificationService>(),
      ),
    );
    await gh.singletonAsync<_i264.FontService>(() {
      final i = _i264.FontService(
        settings: gh<_i264.SettingsService>(),
        pathService: gh<_i264.AppPathService>(),
      );
      return i.init().then((_) => i);
    }, preResolve: true);
    return this;
  }
}
