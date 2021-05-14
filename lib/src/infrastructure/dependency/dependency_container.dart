import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:woog_api/src/infrastructure/dependency/dependency_container.config.dart';

@InjectableInit()
Future<void> configureDependencies(GetIt getIt) => $initGetIt(getIt);
