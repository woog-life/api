import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:woog_api/src/application/repository/unit_of_work.dart';
import 'package:woog_api/src/interface/api/dispatcher.dart';
import 'package:woog_api/src/interface/api/http_constants.dart';
import 'package:woog_api/src/interface/api/middleware/cors.dart';
import 'package:woog_api/src/interface/api/middleware/logging.dart';
import 'package:woog_api/src/interface/api/middleware/opentelemetry.dart';
import 'package:woog_api/src/interface/api/middleware/sentry.dart';

@injectable
@immutable
final class WoogApi {
  final OpenTelemetryMiddleware _openTelemetryMiddleware;
  final LoggingMiddleware _loggingMiddleware;
  final SentryMiddleware _sentryMiddleware;
  final Dispatcher _dispatcher;
  final Logger _logger;
  final UnitOfWorkProvider _uowProvider;
  late final Handler handler;

  WoogApi(
    this._openTelemetryMiddleware,
    this._loggingMiddleware,
    this._sentryMiddleware,
    this._dispatcher,
    this._logger,
    this._uowProvider,
  ) {
    handler = const Pipeline()
        .addMiddleware(_sentryMiddleware)
        .addMiddleware(_loggingMiddleware)
        .addMiddleware(_openTelemetryMiddleware)
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
      // This shouldn't be here, but who cares.
      await _uowProvider.dispose();
      _logger.i('Server is closed.');
    });
  }
}
