import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:woog_api/src/infrastructure/api/woog_api.dart';
import 'package:woog_api/src/infrastructure/dependency/dependency_container.dart';

class Application {
  final GetIt _getIt;
  final Logger logger;

  factory Application() {
    final getIt = GetIt.asNewInstance();
    configureDependencies(getIt);
    return Application._(getIt);
  }

  Application._(
    this._getIt,
  ) : logger = _getIt<Logger>();

  Future<void> launch() async {
    final api = _getIt<WoogApi>();
    await api.launch();
  }
}
