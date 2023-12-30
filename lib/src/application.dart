import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:woog_api/src/interface/api/woog_api.dart';
import 'package:woog_api/src/config.dart';
import 'package:woog_api/src/infrastructure/dependency/dependency_container.dart';

@immutable
final class Application {
  final GetIt _getIt;
  final Logger logger;

  Config get config => _getIt<Config>();

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
    await _launchApi();
  }
}
