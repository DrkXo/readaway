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

import '../services/services.dart' as _i264;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    await gh.singletonAsync<_i264.LoggingService>(() {
      final i = _i264.LoggingService();
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.singleton<_i264.DocumentParserService>(
      () => _i264.DocumentParserService(
        loggingService: gh<_i264.LoggingService>(),
      ),
    );
    return this;
  }
}
