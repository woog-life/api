import 'package:injectable/injectable.dart';
import 'package:sentry/sentry.dart';
import 'package:woog_api/src/infrastructure/config.dart';
import 'package:woog_api/src/infrastructure/sentry/sentry_state.dart';

@module
abstract base class SentryModule {
  @preResolve
  @singleton
  Future<SentryState> createSentry(
    Config config,
  ) async {
    final dsn = config.sentryDsn;
    if (dsn.isNotEmpty) {
      await Sentry.init(
        (options) {
          options.dsn = dsn;
          options.release = '${config.version}+${config.build}';
        },
      );
      return SentryState(isEnabled: true);
    } else {
      return SentryState(isEnabled: false);
    }
  }
}
