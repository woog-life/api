import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/infrastructure/respository/booking_postgres.dart';
import 'package:woog_api/src/infrastructure/respository/lake_postgres.dart';
import 'package:woog_api/src/infrastructure/respository/postgres.dart';
import 'package:woog_api/src/infrastructure/respository/temperature_postgres.dart';

abstract class RepositoryMigrator {
  Future<void> upgrade(
    PostgreSQLExecutionContext transaction,
    int oldVersion,
    int newVersion,
  );
}

const tableName = 'migrator2';
const keyVersion = 'version';

@injectable
class Migrator {
  final int newestVersion = 12;

  final Logger _logger;
  final GetIt _getIt;
  final SqlLakeRepositoryMigrator _lakeRepositoryMigrator;
  final SqlTemperatureRepositoryMigrator _temperatureRepositoryMigrator;
  final SqlBookingRepositoryMigrator _bookingRepositoryMigrator;

  Migrator(
    this._logger,
    this._getIt,
    this._lakeRepositoryMigrator,
    this._temperatureRepositoryMigrator,
    this._bookingRepositoryMigrator,
  );

  Future<void> migrate() async {
    await _getIt.useConnection((connection) async {
      final table = await connection.query(
        '''
      SELECT * FROM information_schema.tables
      WHERE table_name = '$tableName';
      ''',
      );
      if (table.isEmpty) {
        _logger.i('Creating version table');
        await connection.transaction((connection) async {
          await _createVersionTable(connection);
        });
      }
      await _upgrade(connection);
    });
  }

  Future<void> _upgrade(PostgreSQLConnection connection) async {
    final lock = await _Lock.obtain(_logger, connection);
    try {
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
          await _temperatureRepositoryMigrator.upgrade(
            connection,
            version,
            newestVersion,
          );
          await _bookingRepositoryMigrator.upgrade(
            connection,
            version,
            newestVersion,
          );
        });
      } else {
        _logger.i('Database schema is up-to-date');
      }
    } finally {
      await lock.unlock();
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
    await _setVersion(connection, 1);
  }
}

class _Lock {
  static const _key = 'lock';

  final PostgreSQLConnection _connection;
  bool _isLocked;

  _Lock._locked(this._connection) : _isLocked = true;

  static Future<_Lock> obtain(
    Logger logger,
    PostgreSQLConnection connection,
  ) async {
    while (true) {
      logger.d('Trying to obtain migration lock');
      try {
        await connection.execute(
          '''
          INSERT INTO $tableName (key, value)
          VALUES (@key, @value);
          ''',
          substitutionValues: {'key': _key, 'value': 1},
        );
        return _Lock._locked(connection);
      } on PostgreSQLException catch (e) {
        if (e.code == '23505') {
          logger.i('Waiting for lock to be released');
          await Future.delayed(const Duration(seconds: 5));
        } else {
          logger.e('Could not obtain lock', e);
          rethrow;
        }
      }
    }
  }

  Future<void> unlock() async {
    if (_isLocked) {
      await _connection.execute(
        '''
        DELETE FROM $tableName
        WHERE key = @key;
        ''',
        substitutionValues: {'key': _key},
      );
      _isLocked = false;
    } else {
      throw StateError('Not in locked state');
    }
  }
}
