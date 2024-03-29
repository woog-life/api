import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:woog_api/src/infrastructure/dependency/dependency_container.config.dart';

@InjectableInit(
  preferRelativeImports: false,
  asExtension: false,
  initializerName: '\$initGetIt',
  ignoreUnregisteredTypes: [GetIt],
)
Future<void> configureDependencies(GetIt getIt) => $initGetIt(
      getIt,
      environment: Environment.prod,
    );
