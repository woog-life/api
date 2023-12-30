import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/application/repository/tides.dart';

abstract interface class UnitOfWork {
  LakeRepository get lakeRepo;

  TemperatureRepository get temperatureRepo;

  TidesRepository get tidesRepo;
}

abstract interface class UnitOfWorkProvider {
  Future<T> withUnitOfWork<T>({
    required String name,
    required Future<T> Function(UnitOfWork) action,
  });

  bool get isReady;

  Future<void> dispose();
}
