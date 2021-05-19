import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/infrastructure/config.dart';

@module
abstract class PostgresConnectionModule {
  @prod
  Future<PostgreSQLConnection> createConnection(
    Logger logger,
    Config config,
  ) async {
    logger.i('Initializing database');
    final connection = PostgreSQLConnection(
      config.databaseHost,
      int.parse(config.databasePort),
      config.databaseName,
      username: config.databaseUser,
      password: config.databasePassword,
    );
    await connection.open();
    return connection;
  }
}
