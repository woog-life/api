import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/application/repository/tides.dart';

abstract interface class UnitOfWork {
  LakeRepository get lakeRepo;
  TemperatureRepository get temperatureRepo;
  TidesRepository get tidesRepo;
}

abstract interface class UnitOfWorkProvider {
  Future<T> withUnitOfWork<T>(Future<T> Function(UnitOfWork uow) action);
  Future<void> dispose();
}
