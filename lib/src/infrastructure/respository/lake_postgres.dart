import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/application/model/lake.dart';
import 'package:woog_api/src/infrastructure/respository/postgres.dart';

const tableName = 'lake';
const columnId = 'id';
const columnName = 'name';
const columnSupportsTemperature = 'supports_temperature';
const columnSupportsBooking = 'supports_booking';

@prod
@Injectable(as: LakeRepository)
@immutable
final class SqlLakeRepository implements LakeRepository {
  final GetIt _getIt;

  SqlLakeRepository(this._getIt);

  Lake _lakeFromRow(Map<String, dynamic> row) {
    final id = row[columnId];
    final name = row[columnName];

    final features = <Feature>{};
    if (row[columnSupportsTemperature] as bool) {
      features.add(Feature.temperature);
    }

    return Lake(
      id: Uuid.fromString(id as String),
      name: name as String,
      features: features,
    );
  }

  @override
  Future<Set<Lake>> getLakes() async {
    return _getIt.useConnection((connection) async {
      final result = await connection.mappedResultsQuery(
        'SELECT * FROM $tableName',
      );
      return result.map((e) => e[tableName]!).map(_lakeFromRow).toSet();
    });
  }

  @override
  Future<Lake?> getLake(Uuid lakeId) async {
    return _getIt.useConnection((connection) async {
      final lakeRows = await connection.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
        },
      );
      if (lakeRows.isEmpty) {
        return null;
      }

      final row = lakeRows.single;
      final lakeRow = row[tableName]!;
      return _lakeFromRow(lakeRow);
    });
  }
}
