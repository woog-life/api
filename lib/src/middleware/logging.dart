import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';

final _logger = Logger(
  printer: SimplePrinter(),
  filter: ProductionFilter(),
);

Middleware logMiddleware() {
  return logRequests(
    logger: (String msg, bool isError) {
      if (isError) {
        _logger.e(msg);
      } else {
        _logger.i(msg);
      }
    },
  );
}
