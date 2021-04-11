import 'package:shelf/shelf.dart';
import 'package:woog_api/src/logger.dart';

Middleware logMiddleware() {
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
