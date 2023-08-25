import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/infrastructure/config.dart';

@module
abstract base class PostgresConnectionModule {
  @prod
  Future<PostgreSQLConnection> createConnection(
    Logger logger,
    Config config,
  ) async {
    logger.t('Connecting to database server');
    final connection = PostgreSQLConnection(
      config.databaseHost,
      5432,
      config.databaseName,
      username: config.databaseUser,
      password: config.databasePassword,
      useSSL: config.databaseUseTls,
    );
    await connection.open();
    return connection;
  }
}
