import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:woog_api/src/infrastructure/config.dart';

@injectable
class StaticServer {
  final Handler _handler;

  static Response _dummyHandler(Request request) {
    return Response.ok('No docs path mounted');
  }

  static Handler _createStaticHandler(String docsPath) {
    if (docsPath.isEmpty) {
      return _dummyHandler;
    } else {
      return createStaticHandler(
        docsPath,
        defaultDocument: 'index.html',
      );
    }
  }

  StaticServer(Config config)
      : _handler = _createStaticHandler(config.docsPath);

  FutureOr<Response> call(Request request) {
    return _handler(request);
  }
}
