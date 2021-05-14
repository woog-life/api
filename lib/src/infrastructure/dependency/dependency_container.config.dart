// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:logger/logger.dart' as _i5;

import '../../application/repository/lake.dart' as _i3;
import '../api/dispatcher.dart' as _i9;
import '../api/middleware/logging.dart' as _i6;
import '../api/router/private.dart' as _i7;
import '../api/router/public.dart' as _i8;
import '../api/woog_api.dart' as _i10;
import '../respository/lake_memory.dart' as _i4;
import 'logger.dart' as _i11; // ignore_for_file: unnecessary_lambdas

// ignore_for_file: lines_longer_than_80_chars
/// initializes the registration of provided dependencies inside of [GetIt]
_i1.GetIt $initGetIt(_i1.GetIt get,
    {String? environment, _i2.EnvironmentFilter? environmentFilter}) {
  final gh = _i2.GetItHelper(get, environment, environmentFilter);
  final loggerModule = _$LoggerModule();
  gh.factory<_i3.LakeRepository>(() => _i4.MemoryLakeRepository());
  gh.factory<_i5.Logger>(() => loggerModule.createLogger());
  gh.factory<_i6.LoggingMiddleware>(
      () => _i6.LoggingMiddleware(get<_i5.Logger>()));
  gh.factory<_i7.PrivateApi>(() => _i7.PrivateApi(get<_i3.LakeRepository>()));
  gh.factory<_i8.PublicApi>(() => _i8.PublicApi(get<_i3.LakeRepository>()));
  gh.factory<_i9.Dispatcher>(
      () => _i9.Dispatcher(get<_i7.PrivateApi>(), get<_i8.PublicApi>()));
  gh.factory<_i10.WoogApi>(
      () => _i10.WoogApi(get<_i6.LoggingMiddleware>(), get<_i9.Dispatcher>()));
  return get;
}

class _$LoggerModule extends _i11.LoggerModule {}
