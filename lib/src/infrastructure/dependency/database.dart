import 'package:injectable/injectable.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:woog_api/src/infrastructure/config.dart';
import 'package:woog_api/src/infrastructure/respository/migrator.dart';

@module
abstract class DatabaseModule {
  @prod
  @preResolve
  @Singleton()
  Future<Database> createDatabase(
    Config config,
    Migrator migrator,
  ) async {
    return databaseFactoryFfi.openDatabase(
      config.databasePath,
      options: OpenDatabaseOptions(
        version: migrator.newestVersion,
        onCreate: migrator.onCreate,
        onUpgrade: migrator.onUpgrade,
        singleInstance: false,
      ),
    );
  }
}
