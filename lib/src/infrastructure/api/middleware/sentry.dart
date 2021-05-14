import 'package:injectable/injectable.dart';
import 'package:sentry/sentry.dart';
import 'package:shelf/shelf.dart';
import 'package:woog_api/src/infrastructure/sentry/sentry_state.dart';

@injectable
class SentryMiddleware {
  final SentryState sentryState;

  SentryMiddleware(this.sentryState);

  Handler call(Handler innerHandler) {
    Future<Response> _handle(Request request) async {
      try {
        return await innerHandler(request);
      } catch (throwable, stackTrace) {
        if (sentryState.isEnabled) {
          await Sentry.captureException(
            throwable,
            stackTrace: stackTrace,
          );
        }
        rethrow;
      }
    }

    return _handle;
  }
}
