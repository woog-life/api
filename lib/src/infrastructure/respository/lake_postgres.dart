import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:postgres/postgres.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/model/lake.dart';
import 'package:woog_api/src/domain/model/lake_data.dart';
import 'package:woog_api/src/infrastructure/respository/migrator.dart';

const lakeTableName = 'lake';
const columnLakeId = 'id';
const columnLakeName = 'name';

const dataTableName = 'lake_data';
const columnDataId = 'lake_id';
const columnDataTime = 'timestamp';
const columnDataTemperature = 'temperature';

@prod
@Injectable(as: LakeRepository)
class SqlLakeRepository implements LakeRepository {
  final GetIt _getIt;

  Future<PostgreSQLConnection> get _connection => _getIt.getAsync();

  SqlLakeRepository(this._getIt);

  Lake _lakeFromColumns(Map<String, dynamic> row) {
    final id = row[columnLakeId];
    final name = row[columnLakeName];
    return Lake(
      id: id as String,
      name: name as String,
    );
  }

  LakeData _dataFromColumns(Map<String, dynamic> row) {
    final temperature = row[columnDataTemperature];
    final timestamp = row[columnDataTime];

    return LakeData(
      time: timestamp as DateTime,
      temperature: temperature as double,
    );
  }

  @override
  Future<Set<Lake>> getLakes() async {
    final connection = await _connection;
    final result = await connection.mappedResultsQuery(
      'SELECT * FROM $lakeTableName',
    );
    return result.map((e) => e[lakeTableName]!).map(_lakeFromColumns).toSet();
  }

  @override
  Future<Lake?> getLake(String lakeId) async {
    final connection = await _connection;
    final lakeRows = await connection.mappedResultsQuery(
      '''
      SELECT * FROM $lakeTableName
      LEFT JOIN $dataTableName
      ON $lakeTableName.$columnLakeId = $dataTableName.$columnDataId
      WHERE $lakeTableName.$columnLakeId = @lakeId
      ORDER BY $columnDataTime DESC
      LIMIT 1
      ''',
      substitutionValues: {
        'lakeId': lakeId,
      },
    );
    if (lakeRows.isEmpty) {
      return null;
    } else {
      final row = lakeRows.first;
      final lakeRow = row[lakeTableName]!;
      final id = lakeRow[columnLakeId]! as String;
      final name = lakeRow[columnLakeName]! as String;

      final dataRow = row[dataTableName]!;
      final time = dataRow[columnDataTime] as DateTime?;
      final value = dataRow[columnDataTemperature] as double?;

      final LakeData? data;
      if (time != null && value != null) {
        data = LakeData(
          time: time,
          temperature: value,
        );
      } else {
        data = null;
      }

      return Lake(
        id: id,
        name: name,
        data: data,
      );
    }
  }

  @override
  Future<void> updateData(String lakeId, LakeData data) async {
    final connection = await _connection;
    await connection.execute(
      '''
      INSERT INTO $dataTableName (
        $columnDataId,
        $columnDataTime,
        $columnDataTemperature
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
  }

  @override
  Future<NearDataDto> getNearestData(String lakeId, DateTime time) async {
    final connection = await _connection;
    final lowerResult = await connection.mappedResultsQuery(
      '''
        SELECT $columnDataTime, $columnDataTemperature
        FROM $dataTableName
        WHERE $columnDataId = @lakeId AND $columnDataTime <= @time
        ORDER BY $columnDataTime DESC
        LIMIT 1
        ''',
      substitutionValues: {
        'lakeId': lakeId,
        'time': time,
      },
    );

    final higherResult = await connection.mappedResultsQuery(
      '''
        SELECT $columnDataTime, $columnDataTemperature
        FROM $dataTableName
        WHERE $columnDataId = @lakeId AND $columnDataTime >= @time    
        ORDER BY $columnDataTime ASC
        LIMIT 1
        ''',
      substitutionValues: {
        'lakeId': lakeId,
        'time': time,
      },
    );

    final lower = lowerResult.isEmpty
        ? null
        : _dataFromColumns(lowerResult.single[dataTableName]!);
    final higher = higherResult.isEmpty
        ? null
        : _dataFromColumns(higherResult.single[dataTableName]!);

    return NearDataDto(before: lower, after: higher);
  }
}

@injectable
class SqlLakeRepositoryMigrator implements RepositoryMigrator {
  static final _lakes = [
    Lake(
      id: '69c8438b-5aef-442f-a70d-e0d783ea2b38',
      name: 'Großer Woog',
    ),
    Lake(
      id: '25aa2968-e34e-4f86-87cc-56b16b5aff36',
      name: 'Arheilger Mühlchen',
    ),
    Lake(
      id: '55e5f52a-2de8-458a-828f-3c043ef458d9',
      name: 'Alster in Hamburg',
    ),
    Lake(
      id: 'd074654c-dedd-46c3-8042-af55c93c910e',
      name: 'Nordsee bei Cuxhaven',
    ),
    Lake(
      id: 'bedbdac7-7d61-48d5-b1bd-0de5be25e953',
      name: 'Potsdam',
    ),
  ];

  Future<void> _create(PostgreSQLExecutionContext batch) async {
    await batch.execute(
      '''
      CREATE TABLE $lakeTableName (
        $columnLakeId uuid PRIMARY KEY,
        $columnLakeName varchar(128) NOT NULL
      );
      ''',
    );
    await batch.execute(
      '''
      CREATE TABLE $dataTableName (
        $columnDataId uuid REFERENCES $lakeTableName($columnLakeId)
          ON DELETE CASCADE,
        $columnDataTime timestamp NOT NULL,
        $columnDataTemperature real NOT NULL,
        UNIQUE ($columnDataId, $columnDataTime)
      );
      ''',
    );
    await batch.execute(
      '''
        CREATE INDEX idx_timestamp ON $dataTableName (
          $columnDataId,
          $columnDataTime
        ) 
        ''',
    );
    await _insertLake(batch, _lakes[0]);
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
    if (oldVersion < 3 && newVersion >= 3) {
      await _insertLake(transaction, _lakes[1]);
    }
    if (oldVersion < 6 && newVersion >= 6) {
      await _insertLake(transaction, _lakes[2]);
    }
    if (oldVersion < 7 && newVersion >= 7) {
      await _insertLake(transaction, _lakes[3]);
    }
  }

  Future<void> _insertLake(
    PostgreSQLExecutionContext transaction,
    Lake lake,
  ) async {
    await transaction.execute(
      '''
        INSERT INTO $lakeTableName (
          $columnLakeId,
          $columnLakeName
        )
        VALUES (
          @id,
          @name
        )
      ''',
      substitutionValues: {
        'id': lake.id,
        'name': lake.name,
      },
    );
  }
}
