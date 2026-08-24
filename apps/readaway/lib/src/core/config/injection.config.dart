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

import '../../features/reader/presentation/bloc/reader_bloc.dart' as _i523;
import '../../features/settings/presentation/bloc/settings_bloc.dart' as _i585;
import '../../features/settings/presentation/bloc/tts_bloc.dart' as _i992;
import '../../router/router.dart' as _i295;
import '../routes/routes.dart' as _i494;
import '../services/css_service.dart' as _i213;
import '../services/services.dart' as _i264;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i264.HiveConfigService>(() => _i264.HiveConfigService());
    gh.singleton<_i494.AppRoutes>(() => _i494.AppRoutes());
    gh.singleton<_i213.CssService>(() => _i213.CssService());
    gh.singleton<_i264.AppLifecycleManager>(() => _i264.AppLifecycleManager());
    await gh.singletonAsync<_i264.LoggingService>(() {
      final i = _i264.LoggingService();
      return i.init().then((_) => i);
    }, preResolve: true);
    await gh.singletonAsync<_i264.DeviceTtsService>(
      () {
        final i = _i264.DeviceTtsService();
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i264.JustAudioService>(
      () {
        final i = _i264.JustAudioService();
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i264.WakelockService>(() => _i264.WakelockService());
    await gh.singletonAsync<_i264.WindowService>(
      () {
        final i = _i264.WindowService();
        return i.initialize().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i264.SherpaTtsModelCatalog>(
      () => _i264.SherpaTtsModelCatalog(),
    );
    gh.lazySingleton<_i264.TextChunker>(() => _i264.TextChunker());
    await gh.singletonAsync<_i264.AppStorageService>(
      () {
        final i = _i264.AppStorageService(
          config: gh<_i264.HiveConfigService>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    await gh.lazySingletonAsync<_i264.HttpService>(() {
      final i = _i264.HttpService(logger: gh<_i264.LoggingService>());
      return i.initialize().then((_) => i);
    }, preResolve: true);
    await gh.singletonAsync<_i264.SettingsService>(
      () {
        final i = _i264.SettingsService(storage: gh<_i264.AppStorageService>());
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i585.SettingsBloc>(
      () => _i585.SettingsBloc(
        storage: gh<_i264.AppStorageService>(),
        settingsService: gh<_i264.SettingsService>(),
      ),
    );
    gh.singleton<_i264.IsolateService>(
      () => _i264.IsolateService(loggingService: gh<_i264.LoggingService>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i295.AppRoutesGuards>(
      () => _i295.AppRoutesGuards(appRoutes: gh<_i494.AppRoutes>()),
    );
    gh.lazySingleton<_i264.LookupService>(
      () => _i264.LookupService(gh<_i264.HttpService>()),
    );
    await gh.singletonAsync<_i264.FontService>(() {
      final i = _i264.FontService(settings: gh<_i264.SettingsService>());
      return i.init().then((_) => i);
    }, preResolve: true);
    await gh.singletonAsync<_i264.ThemeService>(
      () {
        final i = _i264.ThemeService(settings: gh<_i264.SettingsService>());
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i264.SherpaOnnxTtsService>(
      () {
        final i = _i264.SherpaOnnxTtsService(
          client: gh<_i264.HttpService>(),
          sherpaTtsModelCatalog: gh<_i264.SherpaTtsModelCatalog>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i992.TtsBloc>(
      () => _i992.TtsBloc(
        ttsService: gh<_i264.SherpaOnnxTtsService>(),
        audio: gh<_i264.JustAudioService>(),
      ),
    );
    gh.singleton<_i295.AppRouter>(
      () => _i295.AppRouter(
        appRoutesGuards: gh<_i295.AppRoutesGuards>(),
        logger: gh<_i264.LoggingService>(),
        appRoutes: gh<_i494.AppRoutes>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i264.MuPdfService>(
      () => _i264.MuPdfService(
        isolateService: gh<_i264.IsolateService>(),
        loggingService: gh<_i264.LoggingService>(),
      ),
    );
    await gh.singletonAsync<_i264.ReaderTtsController>(
      () {
        final i = _i264.ReaderTtsController(
          gh<_i264.DeviceTtsService>(),
          gh<_i264.SherpaOnnxTtsService>(),
          gh<_i264.JustAudioService>(),
          gh<_i264.TextChunker>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i523.ReaderBloc>(
      () => _i523.ReaderBloc(
        windowService: gh<_i264.WindowService>(),
        muPdfService: gh<_i264.MuPdfService>(),
      ),
    );
    return this;
  }
}
