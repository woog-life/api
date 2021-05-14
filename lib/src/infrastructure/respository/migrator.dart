import 'package:injectable/injectable.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:woog_api/src/infrastructure/respository/lake_sql.dart';

abstract class RepositoryMigrator {
  Future<void> create(Batch batch);

  Future<void> upgrade(Batch batch, int oldVersion, int newVersion);
}

@injectable
class Migrator {
  final int newestVersion = 2;

  final SqlLakeRepositoryMigrator _lakeRepositoryMigrator;

  Migrator(
    this._lakeRepositoryMigrator,
  );

  Future<void> onCreate(Database database, int version) async {
    final batch = database.batch();
    _lakeRepositoryMigrator.create(batch);
    await batch.commit();
  }

  Future<void> onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    final batch = database.batch();
    _lakeRepositoryMigrator.upgrade(batch, oldVersion, newVersion);
    await batch.commit();
  }
}
