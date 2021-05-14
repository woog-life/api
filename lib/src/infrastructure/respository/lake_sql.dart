import 'package:injectable/injectable.dart';
import 'package:sqflite_common/sqlite_api.dart';
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
  final Database _database;

  SqlLakeRepository(this._database);

  Lake _lakeFromColumns(Map<String, dynamic> columns) {
    final id = columns[columnLakeId];
    final name = columns[columnLakeName];
    return Lake(
      id: id as String,
      name: name as String,
    );
  }

  LakeData _dataFromColumns(Map<String, dynamic> columns) {
    final temperature = columns[columnDataTemperature];
    final timestamp = columns[columnDataTime];

    return LakeData(
      time: DateTime.fromMillisecondsSinceEpoch(timestamp as int),
      temperature: temperature as double,
    );
  }

  @override
  Future<Set<Lake>> getLakes() async {
    final result = await _database.query(lakeTableName);
    return result.map(_lakeFromColumns).toSet();
  }

  @override
  Future<Lake?> getLake(String lakeId) async {
    final lakeColumns = await _database.rawQuery(
      '''
      SELECT * FROM $lakeTableName
      LEFT JOIN $dataTableName
      ON $lakeTableName.$columnLakeId = $dataTableName.$columnDataId
      WHERE $lakeTableName.$columnLakeId = ?
      ORDER BY $columnDataTime DESC
      LIMIT 1
      ''',
      [lakeId],
    );
    if (lakeColumns.isEmpty) {
      return null;
    } else {
      final columns = lakeColumns.first;
      final id = columns[columnLakeId]! as String;
      final name = columns[columnLakeName]! as String;

      final time = columns[columnDataTime] as int?;
      final value = columns[columnDataTemperature] as double?;

      final LakeData? data;
      if (time != null && value != null) {
        data = LakeData(
          time: DateTime.fromMillisecondsSinceEpoch(time),
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
    await _database.insert(
      dataTableName,
      {
        columnDataId: lakeId,
        columnDataTime: data.time.millisecondsSinceEpoch,
        columnDataTemperature: data.temperature,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<NearDataDto> getNearestData(String lakeId, DateTime time) async {
    final lowerResult = await _database.query(dataTableName,
        columns: [
          'max($columnDataTime) as $columnDataTime',
          columnDataTemperature,
        ],
        where: '$columnDataId = ? AND $columnDataTime <= ?',
        whereArgs: [lakeId, time.millisecondsSinceEpoch]);

    final higherResult = await _database.query(dataTableName,
        columns: [
          'min($columnDataTime) as $columnDataTime',
          columnDataTemperature,
        ],
        where: '$columnDataId = ? AND $columnDataTime >= ?',
        whereArgs: [lakeId, time.millisecondsSinceEpoch]);

    final lower =
        lowerResult.isEmpty ? null : _dataFromColumns(lowerResult.single);
    final higher =
        higherResult.isEmpty ? null : _dataFromColumns(higherResult.single);

    return NearDataDto(before: lower, after: higher);
  }
}

@injectable
class SqlLakeRepositoryMigrator implements RepositoryMigrator {
  @override
  Future<void> create(Batch batch) async {
    batch.execute(
      '''
      CREATE TABLE $lakeTableName (
        $columnLakeId TEXT PRIMARY KEY,
        $columnLakeName TEXT NOT NULL
      );
      ''',
    );
    batch.execute(
      '''
      CREATE TABLE $dataTableName (
        $columnDataId TEXT REFERENCES $lakeTableName($columnLakeId)
          ON DELETE CASCADE,
        $columnDataTime INTEGER NOT NULL,
        $columnDataTemperature REAL NOT NULL,
        UNIQUE ($columnDataId, $columnDataTime)
      );
      ''',
    );
    batch.insert(
      lakeTableName,
      {
        columnLakeId: bigWoog.id,
        columnLakeName: bigWoog.name,
      },
    );

    await upgrade(batch, 1, 2);
  }

  @override
  Future<void> upgrade(Batch batch, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      batch.execute(
        '''
        CREATE INDEX idx_timestamp ON $dataTableName (
          $columnDataId,
          $columnDataTime
        ) 
        ''',
      );
    }
  }
}
