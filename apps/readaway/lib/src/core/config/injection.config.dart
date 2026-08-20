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
import '../../router/router.dart' as _i295;
import '../routes/routes.dart' as _i494;
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
    await gh.singletonAsync<_i264.LoggingService>(() {
      final i = _i264.LoggingService();
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.singleton<_i264.AppLifecycleManager>(() => _i264.AppLifecycleManager());
    gh.singleton<_i523.ReaderBloc>(() => _i523.ReaderBloc());
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
    gh.singleton<_i585.SettingsBloc>(
      () => _i585.SettingsBloc(storage: gh<_i264.AppStorageService>()),
    );
    gh.singleton<_i264.DocumentParserService>(
      () => _i264.DocumentParserService(
        loggingService: gh<_i264.LoggingService>(),
      ),
    );
    gh.lazySingleton<_i295.AppRoutesGuards>(
      () => _i295.AppRoutesGuards(appRoutes: gh<_i494.AppRoutes>()),
    );
    gh.singleton<_i295.AppRouter>(
      () => _i295.AppRouter(
        appRoutesGuards: gh<_i295.AppRoutesGuards>(),
        logger: gh<_i264.LoggingService>(),
        appRoutes: gh<_i494.AppRoutes>(),
      ),
      dispose: (i) => i.dispose(),
    );
    return this;
  }
}
