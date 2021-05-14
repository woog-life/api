import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
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
    Logger logger,
    Config config,
    Migrator migrator,
  ) async {
    logger.i('Initializing database');
    sqfliteFfiInit();
    databaseFactoryFfi.setDatabasesPath(config.databasesPath);
    return databaseFactoryFfi.openDatabase(
      'woog.db',
      options: OpenDatabaseOptions(
        version: migrator.newestVersion,
        onCreate: migrator.onCreate,
        onUpgrade: migrator.onUpgrade,
        singleInstance: false,
      ),
    );
  }
}
