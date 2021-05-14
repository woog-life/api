import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:woog_api/src/infrastructure/sentry/sentry_logger.dart';
import 'package:woog_api/src/infrastructure/sentry/sentry_state.dart';

@module
abstract class LoggerModule {
  @injectable
  Logger createLogger(SentryState sentryState) {
    if (sentryState.isEnabled) {
      return SentryLogger(
        printer: SimplePrinter(),
        filter: ProductionFilter(),
      );
    } else {
      return Logger(
        printer: SimplePrinter(),
        filter: ProductionFilter(),
      );
    }
  }
}
