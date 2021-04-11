import 'dart:io';

import 'package:shelf/shelf.dart';

Middleware authMiddleware() {
  final apiKey = Platform.environment['API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw StateError('API_KEY environment variable not set');
  }

  final expectedHeader = 'Bearer $apiKey';

  Response? _handleRequest(Request request) {
    final headerValue = request.headers[HttpHeaders.authorizationHeader];
    if (headerValue == expectedHeader) {
      return null;
    } else if (headerValue == null) {
      return Response(HttpStatus.unauthorized);
    } else {
      return Response(HttpStatus.forbidden);
    }
  }

  return createMiddleware(requestHandler: _handleRequest);
}
