import 'package:meta/meta.dart';
import 'package:opentelemetry/api.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/repository/tides.dart';
import 'package:woog_api/src/infrastructure/respository/postgres_utils.dart';

const tableName = 'tide_data';
const columnId = 'lake_id';
const columnTime = 'time';
const columnHighTide = 'is_high_tide';
const columnHeight = 'height';

@immutable
final class SqlTidesRepository implements TidesRepository {
  final Session _session;
  final Tracer _tracer;

  SqlTidesRepository(this._session)
      : _tracer = globalTracerProvider.getTracer('SqlTidesRepository');

  TidalExtremumData _dataFromColumns(ResultRow row) {
    final columns = row.toColumnMap();
    final isHighTide = columns[columnHighTide];
    final timestamp = columns[columnTime];
    final height = columns[columnHeight];

    return TidalExtremumData(
      isHighTide: isHighTide as bool,
      time: timestamp as DateTime,
      height: height as String,
    );
  }

  @override
  Future<TidalExtremumData?> getLastTidalExtremum({
    required Uuid lakeId,
    required DateTime time,
  }) async {
    final rows = await _session.executePrepared(
      '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId:uuid AND $columnTime < @time:timestamptz
        ORDER BY $columnTime DESC
        LIMIT 1
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
        'time': time,
      },
    );

    if (rows.isEmpty) {
      return null;
    }

    return _dataFromColumns(rows.first);
  }

  @override
  Future<List<TidalExtremumData>> getTidalExtremaAfter({
    required Uuid lakeId,
    required DateTime time,
    required int limit,
  }) async {
    final rows = await _session.executePrepared(
      '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId:uuid AND $columnTime >= @time:timestamptz
        ORDER BY $columnTime ASC
        LIMIT @limit:int4
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
        'time': time,
        'limit': limit,
      },
    );

    if (rows.isEmpty) {
      return [];
    }

    return rows.map(_dataFromColumns).toList(growable: false);
  }

  @override
  Future<void> deleteBetween({
    required Uuid lakeId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async {
    await _session.executePrepared(
      '''
        DELETE FROM $tableName
        WHERE $columnId = @lakeId:uuid
        AND $columnTime >= @startTime:timestamptz
        AND $columnTime <= @endTime:timestamptz
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
        'startTime': startInclusive,
        'endTime': endInclusive,
      },
    );
  }

  @override
  Future<void> delete({
    required Uuid lakeId,
    required DateTime time,
  }) async {
    await _session.executePrepared(
      '''
        DELETE FROM $tableName
        WHERE $columnId = @lakeId:uuid
        AND $columnTime = @time:timestamptz
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
        'time': time,
      },
    );
  }

  @override
  Future<void> insertData(Uuid lakeId, List<TidalExtremumData> data) async {
    final sql = '''
      INSERT INTO $tableName (
        $columnId,
        $columnHighTide,
        $columnTime,
        $columnHeight
      )
      VALUES (
         @lakeId:uuid,
         @highTide:boolean,
         @time:timestamptz,
         @height:text
      )
    ''';
    await _tracer.withDatabaseSpan(
      sql: sql,
      action: () async {
        final statement = await _session.prepare(Sql.named(sql));
        try {
          final inserts = data
              .map((extremum) => statement.run({
                    'lakeId': lakeId.toString(),
                    'time': extremum.time,
                    'highTide': extremum.isHighTide,
                    'height': extremum.height,
                  }))
              .toList(growable: false);
          await Future.wait(inserts);
        } finally {
          await statement.dispose();
        }
      },
    );
  }
}
