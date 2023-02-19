import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';
import 'package:woog_api/src/infrastructure/respository/postgres.dart';

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
  Future<LakeData?> getLakeData(Uuid lakeId) async {
    return _getIt.useConnection((connection) async {
      final rows = await connection.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId
        ORDER BY $columnTime DESC
        LIMIT 1
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
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
  Future<void> updateData(Uuid lakeId, LakeData data) async {
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
          'lakeId': lakeId.toString(),
          'time': data.time,
          'temperature': data.temperature,
        },
      );
    });
  }

  @override
  Future<NearDataDto> getNearestData(Uuid lakeId, DateTime time) async {
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
          'lakeId': lakeId.toString(),
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
          'lakeId': lakeId.toString(),
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

  @override
  Future<LakeDataExtrema?> getExtrema(Uuid lakeId) {
    return _getIt.useConnection((connection) async {
      final minResult = await connection.mappedResultsQuery(
        '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId AND $columnTemperature = (
          SELECT MIN ($columnTemperature)
          FROM $tableName
          WHERE $columnId = @lakeId
        )
        ORDER BY $columnTime ASC
        LIMIT 1
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
        },
      );

      final maxResult = await connection.mappedResultsQuery(
        '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId AND $columnTemperature = (
          SELECT MAX ($columnTemperature)
          FROM $tableName
          WHERE $columnId = @lakeId
        )
        ORDER BY $columnTime ASC
        LIMIT 1
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
        },
      );

      if (minResult.isEmpty || maxResult.isEmpty) {
        return null;
      }

      return LakeDataExtrema(
        min: _dataFromColumns(minResult.single[tableName]!),
        max: _dataFromColumns(maxResult.single[tableName]!),
      );
    });
  }
}
