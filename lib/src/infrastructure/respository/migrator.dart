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

const tableName = 'migrator2';
const oldTableName = 'migrator';
const keyVersion = 'version';

@injectable
class Migrator {
  final int newestVersion = 2;

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
    final isLegacy = await _dropOldTable(connection);
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
        if (!isLegacy) {
          await _lakeRepositoryMigrator.create(connection);
        }
      });
    } else {
      final row = await connection.query(
        '''
        SELECT value FROM $tableName
        WHERE key = @key
        ''',
        substitutionValues: {'key': keyVersion},
      );
      final version = row.single.single as int;
      if (version < newestVersion) {
        _logger.i('Migrating database from version $version to $newestVersion');
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
      INSERT INTO $tableName (key, value)
      VALUES (@key, @value)
      ON CONFLICT (key)
      DO UPDATE SET value = @value;
      ''',
      substitutionValues: {
        'key': keyVersion,
        'value': version,
      },
    );
  }

  Future<void> _createVersionTable(
    PostgreSQLExecutionContext connection,
  ) async {
    await connection.execute(
      '''
      CREATE TABLE $tableName (
        key varchar(64) PRIMARY KEY,
        value INTEGER NOT NULL
      );
      ''',
    );
    await _setVersion(connection, 2);
  }

  Future<bool> _dropOldTable(PostgreSQLExecutionContext connection) async {
    final table = await connection.query(
      '''
      SELECT * FROM information_schema.tables
      WHERE table_name = '$oldTableName';
      ''',
    );
    if (table.isNotEmpty) {
      await connection.execute('''
        DROP TABLE $oldTableName;
        ''');
      return true;
    } else {
      return false;
    }
  }
}
