import 'package:logger/logger.dart';
import 'package:sentry/sentry.dart';

class SentryLogger extends Logger {
  SentryLogger({
    LogFilter? filter,
    LogPrinter? printer,
    LogOutput? output,
    Level? level,
  }) : super(
          filter: filter,
          printer: printer,
          output: output,
          level: level,
        );

  @override
  void log(
    Level level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message.toString(),
      level: _toSentryLevel(level),
    ));
    super.log(level, message, error, stackTrace);
  }

  SentryLevel _toSentryLevel(Level level) {
    switch (level) {
      case Level.verbose:
      case Level.nothing:
      case Level.debug:
        return SentryLevel.debug;
      case Level.info:
        return SentryLevel.info;
      case Level.warning:
        return SentryLevel.warning;
      case Level.error:
        return SentryLevel.error;
      case Level.wtf:
        return SentryLevel.fatal;
    }
  }
}
