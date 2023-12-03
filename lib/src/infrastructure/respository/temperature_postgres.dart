import 'package:meta/meta.dart';
import 'package:opentelemetry/api.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/lake_data.dart';
import 'package:woog_api/src/application/repository/temperature.dart';
import 'package:woog_api/src/infrastructure/respository/postgres_utils.dart';

const tableName = 'lake_data';
const columnId = 'lake_id';
const columnTime = 'timestamp';
const columnTemperature = 'temperature';

@immutable
final class SqlTemperatureRepository implements TemperatureRepository {
  final Session _session;
  final Tracer _tracer;

  SqlTemperatureRepository(this._session, this._tracer);

  LakeData _dataFromColumns(ResultRow row) {
    final columns = row.toColumnMap();
    final temperature = columns[columnTemperature];
    final timestamp = columns[columnTime];

    return LakeData(
      time: timestamp as DateTime,
      temperature: temperature as double,
    );
  }

  @override
  Future<LakeData?> getLakeData(Uuid lakeId) async {
    final rows = await _session.executePrepared(
      '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId:uuid
        ORDER BY $columnTime DESC
        LIMIT 1
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
      },
      tracer: _tracer,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _dataFromColumns(rows.single);
  }

  @override
  Future<void> updateData(Uuid lakeId, LakeData data) async {
    await _session.executePrepared(
      '''
      INSERT INTO $tableName (
        $columnId,
        $columnTime,
        $columnTemperature
      )
      VALUES (
         @lakeId:uuid,
         @time:timestamptz,
         @temperature:float4
      )
      ON CONFLICT DO NOTHING
      ''',
      parameters: {
        'lakeId': lakeId.toString(),
        'time': data.time,
        'temperature': data.temperature,
      },
      tracer: _tracer,
    );
  }

  @override
  Future<NearDataDto> getNearestData(Uuid lakeId, DateTime time) async {
    final lowerResult = await _session.executePrepared(
      '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId:uuid AND $columnTime <= @time:timestamptz
        ORDER BY $columnTime DESC
        LIMIT 1
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
        'time': time,
      },
      tracer: _tracer,
    );

    final higherResult = await _session.executePrepared(
      '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId:uuid AND $columnTime >= @time:timestamptz
        ORDER BY $columnTime ASC
        LIMIT 1
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
        'time': time,
      },
      tracer: _tracer,
    );

    final lower =
        lowerResult.isEmpty ? null : _dataFromColumns(lowerResult.single);
    final higher =
        higherResult.isEmpty ? null : _dataFromColumns(higherResult.single);

    return NearDataDto(before: lower, after: higher);
  }

  @override
  Future<LakeDataExtrema?> getExtrema(Uuid lakeId) async {
    final minResult = await _session.executePrepared(
      '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId:uuid AND $columnTemperature = (
          SELECT MIN ($columnTemperature)
          FROM $tableName
          WHERE $columnId = @lakeId:uuid
        )
        ORDER BY $columnTime ASC
        LIMIT 1
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
      },
      tracer: _tracer,
    );

    final maxResult = await _session.executePrepared(
      '''
        SELECT $columnTime, $columnTemperature
        FROM $tableName
        WHERE $columnId = @lakeId:uuid AND $columnTemperature = (
          SELECT MAX ($columnTemperature)
          FROM $tableName
          WHERE $columnId = @lakeId:uuid
        )
        ORDER BY $columnTime ASC
        LIMIT 1
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
      },
      tracer: _tracer,
    );

    if (minResult.isEmpty || maxResult.isEmpty) {
      return null;
    }

    return LakeDataExtrema(
      min: _dataFromColumns(minResult.single),
      max: _dataFromColumns(maxResult.single),
    );
  }
}
