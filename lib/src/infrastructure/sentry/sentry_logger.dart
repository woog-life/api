// ignore_for_file: deprecated_member_use

import 'package:logger/logger.dart';
import 'package:sentry/sentry.dart';

final class SentryLogger extends Logger {
  SentryLogger({
    super.filter,
    super.printer,
    super.output,
    super.level,
  });

  @override
  void log(
    Level level,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message.toString(),
      level: _toSentryLevel(level),
      timestamp: time,
    ));
    super.log(
      level,
      message,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  SentryLevel _toSentryLevel(Level level) {
    switch (level) {
      case Level.nothing:
      case Level.verbose:
      case Level.off:
      case Level.all:
      case Level.trace:
      case Level.debug:
        return SentryLevel.debug;
      case Level.info:
        return SentryLevel.info;
      case Level.warning:
        return SentryLevel.warning;
      case Level.error:
        return SentryLevel.error;
      case Level.wtf:
      case Level.fatal:
        return SentryLevel.fatal;
    }
  }
}
