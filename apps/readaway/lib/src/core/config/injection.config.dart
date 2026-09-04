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
import '../services/app_lyfecycle_manager.dart' as _i313;
import '../services/audio/audio_player_service.dart' as _i370;
import '../services/font_service.dart' as _i662;
import '../services/html_document_parser.dart' as _i865;
import '../services/http/http_service.dart' as _i920;
import '../services/isolate_service.dart' as _i548;
import '../services/logging_service.dart' as _i520;
import '../services/lookup/lookup_service.dart' as _i456;
import '../services/mupdf_service.dart' as _i16;
import '../services/notification_service.dart' as _i941;
import '../services/package_info_service.dart' as _i314;
import '../services/path_service.dart' as _i145;
import '../services/services.dart' as _i264;
import '../services/settings_service.dart' as _i114;
import '../services/storage/hive/app_storage_service.dart' as _i1024;
import '../services/storage/hive/hive_config_service.dart' as _i155;
import '../services/theme_service.dart' as _i982;
import '../services/tts/sherpa/sherpa_model_catalog.dart' as _i468;
import '../services/tts/sherpa/sherpa_onnx_tts_service.dart' as _i572;
import '../services/tts/sherpa/sherpa_tts_model_downloader.dart' as _i590;
import '../services/tts/tts_chunker_service.dart' as _i864;
import '../services/tts/tts_controller_service.dart' as _i573;
import '../services/wakelock_service.dart' as _i669;
import '../services/window_service.dart' as _i516;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i494.AppRoutes>(() => _i494.AppRoutes());
    gh.singleton<_i313.AppLifecycleManager>(() => _i313.AppLifecycleManager());
    await gh.singletonAsync<_i520.LoggingService>(() {
      final i = _i520.LoggingService();
      return i.init().then((_) => i);
    }, preResolve: true);
    await gh.singletonAsync<_i314.PackageInfoService>(() {
      final i = _i314.PackageInfoService();
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.singleton<_i669.WakelockService>(() => _i669.WakelockService());
    await gh.singletonAsync<_i516.WindowService>(
      () {
        final i = _i516.WindowService();
        return i.initialize().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i145.AppPathService>(() => _i145.AppPathService());
    gh.lazySingleton<_i864.TextChunker>(() => _i864.TextChunker());
    await gh.singletonAsync<_i941.NotificationService>(
      () {
        final i = _i941.NotificationService(gh<_i314.PackageInfoService>());
        return i.initialize().then((_) => i);
      },
      dependsOn: [_i314.PackageInfoService],
      preResolve: true,
    );
    await gh.singletonAsync<_i370.AudioPlayerService>(
      () {
        final i = _i370.AudioPlayerService(
          gh<_i314.PackageInfoService>(),
          gh<_i941.NotificationService>(),
        );
        return i.init().then((_) => i);
      },
      dependsOn: [
        _i520.LoggingService,
        _i941.NotificationService,
        _i314.PackageInfoService,
      ],
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i428.DocumentParser<String>>(
      () => const _i865.HtmlDocumentParser(),
    );
    gh.factory<_i155.HiveConfigService>(
      () => _i155.HiveConfigService(gh<_i145.AppPathService>()),
    );
    gh.singleton<_i548.IsolateService>(
      () => _i548.IsolateService(loggingService: gh<_i520.LoggingService>()),
      dispose: (i) => i.dispose(),
    );
    await gh.lazySingletonAsync<_i920.HttpService>(() {
      final i = _i920.HttpService(
        logger: gh<_i520.LoggingService>(),
        pathService: gh<_i145.AppPathService>(),
      );
      return i.initialize().then((_) => i);
    }, preResolve: true);
    gh.lazySingleton<_i468.SherpaTtsModelCatalogService>(
      () => _i468.SherpaTtsModelCatalogService(
        httpService: gh<_i920.HttpService>(),
      ),
    );
    gh.lazySingleton<_i456.LookupService>(
      () => _i456.LookupService(gh<_i920.HttpService>()),
    );
    gh.lazySingleton<_i295.AppRoutesGuards>(
      () => _i295.AppRoutesGuards(appRoutes: gh<_i494.AppRoutes>()),
    );
    gh.singleton<_i590.SherpaTtsModelDownloaderService>(
      () => _i590.SherpaTtsModelDownloaderService(
        client: gh<_i920.HttpService>(),
        catalog: gh<_i468.SherpaTtsModelCatalogService>(),
        pathService: gh<_i145.AppPathService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i572.SherpaOnnxTtsService>(
      () {
        final i = _i572.SherpaOnnxTtsService(
          downloader: gh<_i590.SherpaTtsModelDownloaderService>(),
          sherpaTtsModelCatalog: gh<_i468.SherpaTtsModelCatalogService>(),
          isolateService: gh<_i548.IsolateService>(),
          pathService: gh<_i145.AppPathService>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i864.TtsChunkingService>(
      () => _i864.TtsChunkingService(gh<_i548.IsolateService>()),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i295.AppRouter>(
      () => _i295.AppRouter(
        appRoutesGuards: gh<_i295.AppRoutesGuards>(),
        logger: gh<_i264.LoggingService>(),
        appRoutes: gh<_i494.AppRoutes>(),
      ),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i1024.AppStorageService>(
      () {
        final i = _i1024.AppStorageService(
          config: gh<_i155.HiveConfigService>(),
          isolateService: gh<_i548.IsolateService>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i16.MuPdfService>(
      () => _i16.MuPdfService(
        isolateService: gh<_i548.IsolateService>(),
        loggingService: gh<_i520.LoggingService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i114.SettingsService>(
      () {
        final i = _i114.SettingsService(
          storage: gh<_i1024.AppStorageService>(),
        );
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i982.ThemeService>(
      () {
        final i = _i982.ThemeService(settings: gh<_i114.SettingsService>());
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i228.SettingsBloc>(
      () => _i228.SettingsBloc(
        storage: gh<_i264.AppStorageService>(),
        settingsService: gh<_i264.SettingsService>(),
        ttsService: gh<_i264.SherpaOnnxTtsService>(),
        audioPlayer: gh<_i264.AudioPlayerService>(),
        pathService: gh<_i264.AppPathService>(),
      ),
    );
    gh.lazySingleton<_i573.TtsControllerService>(
      () => _i573.TtsControllerService(
        gh<_i572.SherpaOnnxTtsService>(),
        gh<_i370.AudioPlayerService>(),
        gh<_i864.TtsChunkingService>(),
        gh<_i145.AppPathService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i662.FontService>(() {
      final i = _i662.FontService(
        settings: gh<_i114.SettingsService>(),
        pathService: gh<_i145.AppPathService>(),
      );
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.lazySingleton<_i264.DocumentCoverService>(
      () => _i264.DocumentCoverService(
        gh<_i264.MuPdfService>(),
        gh<_i145.AppPathService>(),
      ),
    );
    gh.factory<_i523.ReaderBloc>(
      () => _i523.ReaderBloc(
        windowService: gh<_i264.WindowService>(),
        muPdfService: gh<_i264.MuPdfService>(),
        ttsController: gh<_i264.TtsControllerService>(),
        settingsBloc: gh<_i228.SettingsBloc>(),
        documentParser: gh<_i428.DocumentParser<String>>(),
        notificationService: gh<_i264.NotificationService>(),
        coverService: gh<_i264.DocumentCoverService>(),
      ),
    );
    return this;
  }
}
