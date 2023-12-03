import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:opentelemetry/api.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/application/repository/tides.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';
import 'package:woog_api/src/infrastructure/config.dart';
import 'package:woog_api/src/infrastructure/respository/lake_postgres.dart';
import 'package:woog_api/src/infrastructure/respository/temperature_postgres.dart';
import 'package:woog_api/src/infrastructure/respository/tides_postgres.dart';

class PostgresUnitOfWork implements UnitOfWork {
  @override
  final Tracer tracer;

  @override
  final LakeRepository lakeRepo;

  @override
  final TemperatureRepository temperatureRepo;

  @override
  final TidesRepository tidesRepo;

  PostgresUnitOfWork(this.tracer, Session session)
      : lakeRepo = SqlLakeRepository(session),
        temperatureRepo = SqlTemperatureRepository(session),
        tidesRepo = SqlTidesRepository(session);
}

@prod
@Singleton(as: UnitOfWorkProvider)
class PostgresUnitOfWorkProvider implements UnitOfWorkProvider {
  final Logger _logger;
  final Pool<void> _connectionPool;
  final TracerProvider _tracerProvider;

  PostgresUnitOfWorkProvider(
    this._logger,
    this._tracerProvider,
    Config config,
  ) : _connectionPool = Pool.withEndpoints(
          [
            Endpoint(
              host: config.databaseHost,
              port: 5432,
              database: config.databaseName,
              username: config.databaseUser,
              password: config.databasePassword,
            )
          ],
          settings: PoolSettings(
            sslMode: config.databaseUseTls ? SslMode.require : SslMode.disable,
          ),
        );

  @override
  Future<T> withUnitOfWork<T>({
    required String name,
    required Future<T> Function(UnitOfWork) action,
  }) async {
    final tracer = _tracerProvider.getTracer('opentelemetry-dart');
    return await trace(
      name,
      () async {
        return await _connectionPool.withConnection(
          (connection) async {
            return await connection.runTx(
              (session) async {
                final uow = PostgresUnitOfWork(tracer, session);
                return await action(uow);
              },
            );
          },
        );
      },
      tracer: tracer,
    );
  }

  @disposeMethod
  @override
  Future<void> dispose() async {
    await _connectionPool.close();
    _logger.i('Closed PostgresUnitOfWorkProvider');
  }
}
