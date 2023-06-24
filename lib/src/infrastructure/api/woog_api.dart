import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
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
  final Logger _logger;
  late final Handler handler;

  WoogApi(
    this._loggingMiddleware,
    this._sentryMiddleware,
    this._dispatcher,
    this._logger,
  ) {
    handler = const Pipeline()
        .addMiddleware(_sentryMiddleware)
        .addMiddleware(_loggingMiddleware)
        .addMiddleware(corsMiddleware())
        .addHandler(_dispatcher);
  }

  void _runOnStopSignals(Future Function(ProcessSignal signal) action) {
    final streams = [
      ProcessSignal.sigint.watch(),
      if (!Platform.isWindows) ProcessSignal.sigterm.watch(),
    ];

    final subscriptions = <StreamSubscription>[];

    for (final stream in streams) {
      subscriptions.add(stream.listen((signal) {
        for (final sub in subscriptions) {
          sub.cancel();
        }
        action(signal);
      }));
    }
  }

  Future<void> launch() async {
    final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
    _runOnStopSignals((signal) async {
      _logger.w('Server is stopping because of a ${signal.name} signal');
      await server.close();
      _logger.i('Server is closed.');
    });
  }
}
