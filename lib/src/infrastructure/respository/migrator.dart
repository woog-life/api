import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/infrastructure/respository/lake_postgres.dart';

abstract class RepositoryMigrator {
  Future<void> create(PostgreSQLExecutionContext transaction);

  Future<void> upgrade(
    PostgreSQLExecutionContext transaction,
    int oldVersion,
    int newVersion,
  );
}

const tableName = 'migrator';
const id = 1;

@injectable
class Migrator {
  final int newestVersion = 1;

  final Logger _logger;
  final GetIt _getIt;
  final SqlLakeRepositoryMigrator _lakeRepositoryMigrator;

  Migrator(
    this._logger,
    this._getIt,
    this._lakeRepositoryMigrator,
  );

  Future<void> migrate() async {
    final connection = await _getIt.getAsync<PostgreSQLConnection>();
    final table = await connection.query(
      '''
      SELECT * FROM information_schema.tables
      WHERE table_name = '$tableName';
      ''',
    );
    if (table.isEmpty) {
      _logger.i('Running initial migration');
      await connection.transaction((connection) async {
        await _createVersionTable(connection);
        await _lakeRepositoryMigrator.create(connection);
      });
    } else {
      final row = await connection.query(
        '''
        SELECT version FROM $tableName
        WHERE id = @id
        ''',
        substitutionValues: {'id': id},
      );
      final version = row.single.single as int;
      if (version < newestVersion) {
        _logger.i('Migrating from $version to $newestVersion');
        await connection.transaction((connection) async {
          await _setVersion(connection, newestVersion);
          await _lakeRepositoryMigrator.upgrade(
            connection,
            version,
            newestVersion,
          );
        });
      } else {
        _logger.i('Database schema is up-to-date');
      }
    }
  }

  Future<void> _setVersion(
    PostgreSQLExecutionContext connection,
    int version,
  ) async {
    await connection.execute(
      '''
      INSERT INTO $tableName (id, version)
      VALUES (@id, @version)
      ''',
      substitutionValues: {
        'id': id,
        'version': version,
      },
    );
  }

  Future<void> _createVersionTable(
    PostgreSQLExecutionContext connection,
  ) async {
    await connection.execute(
      '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY,
        version INTEGER NOT NULL
      );
      ''',
    );
    await _setVersion(connection, 1);
  }
}
