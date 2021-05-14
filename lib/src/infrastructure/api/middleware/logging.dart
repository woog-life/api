import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';

@injectable
class LoggingMiddleware {
  final Middleware _delegate;

  static Middleware _createDelegate(Logger logger) {
    return logRequests(
      logger: (String msg, bool isError) {
        if (isError) {
          logger.e(msg);
        } else {
          logger.i(msg);
        }
      },
    );
  }

  LoggingMiddleware(Logger logger) : _delegate = _createDelegate(logger);

  Handler call(Handler innerHandler) {
    return _delegate(innerHandler);
  }
}
