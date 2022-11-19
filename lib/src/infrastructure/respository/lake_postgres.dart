import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/domain/model/lake.dart';
import 'package:woog_api/src/infrastructure/respository/migrator.dart';
import 'package:woog_api/src/infrastructure/respository/postgres.dart';

const tableName = 'lake';
const columnId = 'id';
const columnName = 'name';
const columnSupportsTemperature = 'supports_temperature';
const columnSupportsBooking = 'supports_booking';

@prod
@Injectable(as: LakeRepository)
class SqlLakeRepository implements LakeRepository {
  final GetIt _getIt;

  SqlLakeRepository(this._getIt);

  Lake _lakeFromRow(Map<String, dynamic> row) {
    final id = row[columnId];
    final name = row[columnName];

    final features = <Feature>{};
    if (row[columnSupportsTemperature] as bool) {
      features.add(Feature.temperature);
    }
    if (row[columnSupportsBooking] as bool) {
      features.add(Feature.booking);
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

@injectable
class SqlLakeRepositoryMigrator implements RepositoryMigrator {
  static final _lakes = [
    Lake(
      id: Uuid.fromString('69c8438b-5aef-442f-a70d-e0d783ea2b38'),
      name: 'Großer Woog',
      features: const {Feature.temperature},
    ),
    Lake(
      id: Uuid.fromString('25aa2968-e34e-4f86-87cc-56b16b5aff36'),
      name: 'Arheilger Mühlchen',
      features: const {},
    ),
    Lake(
      id: Uuid.fromString('55e5f52a-2de8-458a-828f-3c043ef458d9'),
      name: 'Alster in Hamburg',
      features: const {Feature.temperature},
    ),
    Lake(
      id: Uuid.fromString('d074654c-dedd-46c3-8042-af55c93c910e'),
      name: 'Nordsee bei Cuxhaven',
      features: const {Feature.temperature},
    ),
    Lake(
      id: Uuid.fromString('bedbdac7-7d61-48d5-b1bd-0de5be25e953'),
      name: 'Potsdamer Havel',
      features: const {Feature.temperature},
    ),
    Lake(
      id: Uuid.fromString('acf32f07-e702-4e9e-b766-fb8993a71b21'),
      name: 'Aare (Bern Schönau)',
      features: const {Feature.temperature},
    ),
    Lake(
      id: Uuid.fromString('ab337e4e-7673-4b5e-9c95-393f06f548c8'),
      name: 'Rhein (Köln)',
      features: const {Feature.temperature},
    ),
    Lake(
      id: Uuid.fromString('ab6fbeb2-be73-4223-8f04-425929339838'),
      name: 'Blaarmeersen (Gent)',
      features: const {Feature.temperature},
    ),
  ];

  Future<void> _create(PostgreSQLExecutionContext batch) async {
    await batch.execute(
      '''
      CREATE TABLE $tableName (
        $columnId uuid PRIMARY KEY,
        $columnName varchar(128) NOT NULL
      );
      ''',
    );
    await _insertLakeWithoutFeatures(batch, _lakes[0]);
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
      await _insertLakeWithoutFeatures(transaction, _lakes[1]);
    }
    if (oldVersion < 6 && newVersion >= 6) {
      await _insertLakeWithoutFeatures(transaction, _lakes[2]);
    }
    if (oldVersion < 7 && newVersion >= 7) {
      await _insertLakeWithoutFeatures(transaction, _lakes[3]);
    }
    if (oldVersion < 8 && newVersion >= 8) {
      await _insertLakeWithoutFeatures(transaction, _lakes[4]);
    }
    if (oldVersion < 9 && newVersion >= 9) {
      await _insertLakeWithoutFeatures(transaction, _lakes[5]);
    }
    if (oldVersion < 10 && newVersion >= 10) {
      await _addFeatures(transaction);
    }
    if (oldVersion < 11 && newVersion >= 11) {
      await _setFeatures(transaction, _lakes[1]);
    }
    if (oldVersion < 12 && newVersion >= 12) {
      await _insertLake(transaction, _lakes[6]);
    }
    if (oldVersion < 13 && newVersion >= 13) {
      await Future.wait(
        [for (final lake in _lakes) _setFeatures(transaction, lake)],
      );
    }
    if (oldVersion < 14 && newVersion >= 14) {
      await _insertLake(transaction, _lakes[7]);
    }
  }

  Future<void> _insertLakeWithoutFeatures(
    PostgreSQLExecutionContext transaction,
    Lake lake,
  ) async {
    await transaction.execute(
      '''
        INSERT INTO $tableName (
          $columnId,
          $columnName
        )
        VALUES (
          @id,
          @name
        )
      ''',
      substitutionValues: {
        'id': lake.id.toString(),
        'name': lake.name,
      },
    );
  }

  // ignore: unused_element
  Future<void> _insertLake(
    PostgreSQLExecutionContext transaction,
    Lake lake,
  ) async {
    await transaction.execute(
      '''
        INSERT INTO $tableName (
          $columnId,
          $columnName,
          $columnSupportsTemperature,
          $columnSupportsBooking
        )
        VALUES (
          @id,
          @name,
          @supportsTemperature,
          @supportsBooking
        )
      ''',
      substitutionValues: {
        'id': lake.id.toString(),
        'name': lake.name,
        'supportsTemperature': lake.features.contains(Feature.temperature),
        'supportsBooking': lake.features.contains(Feature.booking),
      },
    );
  }

  Future<void> _addFeatures(PostgreSQLExecutionContext transaction) async {
    await transaction.execute(
      '''
        ALTER TABLE $tableName
        ADD COLUMN $columnSupportsTemperature boolean,
        ADD COLUMN $columnSupportsBooking boolean;
      ''',
    );
    for (final lake in _lakes.sublist(0, 6)) {
      await _setFeatures(transaction, lake);
    }
    await transaction.execute(
      '''
        ALTER TABLE $tableName
        ALTER COLUMN $columnSupportsTemperature SET NOT NULL,
        ALTER COLUMN $columnSupportsBooking SET NOT NULL;
      ''',
    );
  }

  Future<void> _setFeatures(
    PostgreSQLExecutionContext transaction,
    Lake lake,
  ) async {
    await transaction.execute(
      '''
        UPDATE $tableName
        SET 
          $columnSupportsTemperature = @supportsTemperature,
          $columnSupportsBooking = @supportsBooking
        WHERE $columnId = @lakeId
      ''',
      substitutionValues: {
        'lakeId': lake.id.toString(),
        'supportsTemperature': lake.features.contains(Feature.temperature),
        'supportsBooking': lake.features.contains(Feature.booking),
      },
    );
  }
}
