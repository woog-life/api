import 'package:injectable/injectable.dart';
import 'package:sqflite_common/sqlite_api.dart';

abstract class RepositoryMigrator {
  Future<void> create(Batch batch);

  Future<void> upgrade(Batch batch, int oldVersion, int newVersion);
}

@injectable
class Migrator {
  final int newestVersion = 1;

  Migrator();

  Future<void> onCreate(Database database, int version) async {
    final batch = database.batch();
    await batch.commit();
  }

  Future<void> onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    final batch = database.batch();
    await batch.commit();
  }
}
