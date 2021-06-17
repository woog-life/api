import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:woog_api/src/infrastructure/api/dispatcher.dart';
import 'package:woog_api/src/infrastructure/api/http_constants.dart';
import 'package:woog_api/src/infrastructure/api/middleware/cors.dart';
import 'package:woog_api/src/infrastructure/api/middleware/logging.dart';
import 'package:woog_api/src/infrastructure/api/middleware/sentry.dart';

@injectable
class WoogApi {
  final LoggingMiddleware _loggingMiddleware;
  final SentryMiddleware _sentryMiddleware;
  final Dispatcher _dispatcher;
  late final Handler handler;

  WoogApi(
    this._loggingMiddleware,
    this._sentryMiddleware,
    this._dispatcher,
  ) {
    handler = const Pipeline()
        .addMiddleware(_sentryMiddleware)
        .addMiddleware(_loggingMiddleware)
        .addMiddleware(corsMiddleware())
        .addHandler(_dispatcher);
  }

  Future<void> launch() async {
    await io.serve(handler, InternetAddress.anyIPv4, 8080);
  }
}
