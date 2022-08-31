import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:woog_api/src/infrastructure/config.dart';

@injectable
class AuthMiddleware {
  final Middleware _delegate;

  AuthMiddleware(Config config) : _delegate = _createDelegate(config.apiKey);

  static Middleware _createDelegate(String apiKey) {
    final expectedHeader = 'Bearer $apiKey';

    Response? handleRequest(Request request) {
      final headerValue = request.headers[HttpHeaders.authorizationHeader];
      if (headerValue == expectedHeader) {
        return null;
      } else if (headerValue == null) {
        return Response(HttpStatus.unauthorized);
      } else {
        return Response(HttpStatus.forbidden);
      }
    }

    return createMiddleware(requestHandler: handleRequest);
  }

  Handler call(Handler innerHandler) => _delegate(innerHandler);
}
