import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/repository/tides.dart';
import 'package:woog_api/src/infrastructure/respository/postgres.dart';

const tableName = 'tide_data';
const columnId = 'lake_id';
const columnTime = 'time';
const columnHighTide = 'is_high_tide';
const columnHeight = 'height';

@Injectable(as: TidesRepository)
@immutable
final class SqlTidesRepository implements TidesRepository {
  final GetIt _getIt;

  SqlTidesRepository(this._getIt);

  TidalExtremumData _dataFromColumns(Map<String, dynamic> row) {
    final isHighTide = row[columnHighTide];
    final timestamp = row[columnTime];
    final height = row[columnHeight];

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
  }) {
    return _getIt.useConnection((connection) async {
      final rows = await connection.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId AND $columnTime < @time
        ORDER BY $columnTime DESC
        LIMIT 1
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
          'time': time,
        },
      );

      if (rows.isEmpty) {
        return null;
      }

      final dataRow = rows[0][tableName]!;
      return _dataFromColumns(dataRow);
    });
  }

  @override
  Future<List<TidalExtremumData>> getTidalExtremaAfter({
    required Uuid lakeId,
    required DateTime time,
    required int limit,
  }) {
    return _getIt.useConnection((connection) async {
      final rows = await connection.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        WHERE $columnId = @lakeId AND $columnTime >= @time
        ORDER BY $columnTime ASC
        LIMIT @limit
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
          'time': time,
          'limit': limit,
        },
      );

      if (rows.isEmpty) {
        return [];
      }

      return rows
          .map((row) => _dataFromColumns(row[tableName]!))
          .toList(growable: false);
    });
  }

  @override
  Future<void> deleteBetween({
    required Uuid lakeId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) {
    return _getIt.useConnection((connection) async {
      await connection.execute(
        '''
        DELETE FROM $tableName
        WHERE $columnId = @lakeId
        AND $columnTime >= @startTime
        AND $columnTime <= @endTime
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
          'startTime': startInclusive,
          'endTime': endInclusive,
        },
      );
    });
  }

  @override
  Future<void> delete({
    required Uuid lakeId,
    required DateTime time,
  }) {
    return _getIt.useConnection((connection) async {
      await connection.execute(
        '''
        DELETE FROM $tableName
        WHERE $columnId = @lakeId
        AND $columnTime = @time
        ''',
        substitutionValues: {
          'lakeId': lakeId.toString(),
          'time': time,
        },
      );
    });
  }

  @override
  Future<void> insertData(Uuid lakeId, List<TidalExtremumData> data) {
    return _getIt.useConnection((connection) async {
      await connection.transaction((connection) {
        return Future.wait(
          data.map((extremum) => connection.execute(
                '''
                INSERT INTO $tableName (
                  $columnId,
                  $columnHighTide,
                  $columnTime,
                  $columnHeight
                )
                VALUES (
                   @lakeId,
                   @highTide,
                   @time,
                   @height
                )
                ''',
                substitutionValues: {
                  'lakeId': lakeId.toString(),
                  'time': extremum.time,
                  'highTide': extremum.isHighTide,
                  'height': extremum.height,
                },
              )),
        );
      });
    });
  }
}
