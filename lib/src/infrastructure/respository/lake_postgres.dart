import 'package:meta/meta.dart';
import 'package:opentelemetry/api.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/infrastructure/respository/postgres_utils.dart';

const tableName = 'lake';
const columnId = 'id';
const columnName = 'name';
const columnTimeZone = 'time_zone_id';
const columnSupportsTemperature = 'supports_temperature';
const columnSupportsTides = 'supports_tides';

@immutable
final class SqlLakeRepository implements LakeRepository {
  final Session _session;
  final Tracer _tracer;

  SqlLakeRepository(this._session, this._tracer);

  Lake _lakeFromRow(ResultRow row) {
    final columns = row.toColumnMap();
    final id = columns[columnId];
    final name = columns[columnName];
    final timeZoneId = columns[columnTimeZone];

    final features = <Feature>{};
    if (columns[columnSupportsTemperature] as bool) {
      features.add(Feature.temperature);
    }
    if (columns[columnSupportsTides] as bool) {
      features.add(Feature.tides);
    }

    return Lake(
      id: Uuid.fromString(id as String),
      name: name as String,
      features: features,
      timeZoneId: timeZoneId as String,
    );
  }

  @override
  Future<Set<Lake>> getLakes() {
    final sql = 'SELECT * FROM $tableName';
    return _tracer.withDatabaseSpan(
      sql: sql,
      action: () async {
        final rows = await _session.execute(sql);
        return rows.map(_lakeFromRow).toSet();
      },
    );
  }

  @override
  Future<Lake?> getLake(Uuid lakeId) async {
    final rows = await _session.executePrepared(
      '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId:uuid
        ''',
      parameters: {
        'lakeId': lakeId.toString(),
      },
      tracer: _tracer,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _lakeFromRow(rows.single);
  }
}
