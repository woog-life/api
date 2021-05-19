import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:woog_api/src/infrastructure/api/woog_api.dart';
import 'package:woog_api/src/infrastructure/dependency/dependency_container.dart';
import 'package:woog_api/src/infrastructure/respository/migrator.dart';

class Application {
  final GetIt _getIt;
  final Logger logger;

  static Future<Application> create() async {
    final getIt = GetIt.asNewInstance();
    await configureDependencies(getIt);
    getIt.registerSingleton(getIt);
    return Application._(getIt);
  }

  Application._(
    this._getIt,
  ) : logger = _getIt<Logger>();

  Future<void> _launchApi() async {
    final api = _getIt<WoogApi>();
    await api.launch();
  }

  Future<void> launch() async {
    await _getIt<Migrator>().migrate();
    await _launchApi();
  }
}
