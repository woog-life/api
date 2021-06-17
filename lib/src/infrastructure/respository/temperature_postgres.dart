import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';
import 'package:woog_api/src/infrastructure/respository/lake_postgres.dart'
    as lake;
import 'package:woog_api/src/infrastructure/respository/migrator.dart';
import 'package:woog_api/src/infrastructure/respository/postres.dart';

const tableName = 'lake_data';
const columnId = 'lake_id';
const columnTime = 'timestamp';
const columnTemperature = 'temperature';

@Injectable(as: TemperatureRepository)
class SqlTemperatureRepository implements TemperatureRepository {
  final GetIt _getIt;

  SqlTemperatureRepository(this._getIt);

  LakeData _dataFromColumns(Map<String, dynamic> row) {
    final temperature = row[columnTemperature];
    final timestamp = row[columnTime];

    return LakeData(
      time: timestamp as DateTime,
      temperature: temperature as double,
    );
  }

  @override
  Future<LakeData?> getLakeData(String lakeId) async {
    return _getIt.useConnection((connection) async {
      final rows = await connection.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId
        ORDER BY $columnTime DESC
        LIMIT 1
        ''',
        substitutionValues: {
          'lakeId': lakeId,
        },
      );

      if (rows.isEmpty) {
        return null;
      }

      final dataRow = rows[0][tableName]!;
      final time = dataRow[columnTime] as DateTime;
      final value = dataRow[columnTemperature] as double;

      return LakeData(
        time: time,
        temperature: value,
      );
    });
  }

  @override
  Future<void> updateData(String lakeId, LakeData data) async {
    return _getIt.useConnection((connection) async {
      await connection.execute(
        '''
      INSERT INTO $tableName (
        $columnId,
        $columnTime,
        $columnTemperature
      )
      VALUES (
         @lakeId,
         @time,
         @temperature
      )
      ON CONFLICT DO NOTHING
      ''',
        substitutionValues: {
          'lakeId': lakeId,
          'time': data.time,
          'temperature': data.temperature,
        },
      );
    });
  }

  @override
  Future<NearDataDto> getNearestData(String lakeId, DateTime time) async {
    return _getIt.useConnection((connection) async {
      final lowerResult = await connection.mappedResultsQuery(
        '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId AND $columnTime <= @time
        ORDER BY $columnTime DESC
        LIMIT 1
        ''',
        substitutionValues: {
          'lakeId': lakeId,
          'time': time,
        },
      );

      final higherResult = await connection.mappedResultsQuery(
        '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId AND $columnTime >= @time    
        ORDER BY $columnTime ASC
        LIMIT 1
        ''',
        substitutionValues: {
          'lakeId': lakeId,
          'time': time,
        },
      );

      final lower = lowerResult.isEmpty
          ? null
          : _dataFromColumns(lowerResult.single[tableName]!);
      final higher = higherResult.isEmpty
          ? null
          : _dataFromColumns(higherResult.single[tableName]!);

      return NearDataDto(before: lower, after: higher);
    });
  }
}

@injectable
class SqlTemperatureRepositoryMigrator implements RepositoryMigrator {
  Future<void> _create(PostgreSQLExecutionContext batch) async {
    await batch.execute(
      '''
      CREATE TABLE $tableName (
        $columnId uuid REFERENCES ${lake.tableName}(${lake.columnId})
          ON DELETE CASCADE,
        $columnTime timestamp NOT NULL,
        $columnTemperature real NOT NULL,
        UNIQUE ($columnId, $columnTime)
      );
      ''',
    );
    await batch.execute(
      '''
        CREATE INDEX idx_timestamp ON $tableName (
          $columnId,
          $columnTime
        ) 
        ''',
    );
  }

  @override
  Future<void> upgrade(
    PostgreSQLExecutionContext transaction,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _create(transaction);
    }
  }
}
