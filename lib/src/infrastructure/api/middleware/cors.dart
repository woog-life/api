import 'dart:io';

import 'package:shelf/shelf.dart';

const _corsHeaders = {'Access-Control-Allow-Origin': '*'};

Middleware corsMiddleware() {
  Response? _handleOptions(Request request) {
    if (request.method == 'OPTIONS') {
      return Response(HttpStatus.ok, headers: _corsHeaders);
    } else {
      return null;
    }
  }

  Response _addCorsHeader(Response response) {
    return response.change(headers: _corsHeaders);
  }

  return createMiddleware(
    requestHandler: _handleOptions,
    responseHandler: _addCorsHeader,
  );
}
