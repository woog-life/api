import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@module
abstract class LoggerModule {
  @injectable
  Logger createLogger() {
    return Logger(
      printer: SimplePrinter(),
      filter: ProductionFilter(),
    );
  }
}
