import 'package:shelf/shelf.dart';

Middleware trailingSlashRedirect() {
  Response? _handleRequest(Request request) {
    final requestPath = request.requestedUri.path;
    if (requestPath.endsWith('/') && requestPath != '/') {
      return Response.movedPermanently(
        requestPath.substring(0, requestPath.length - 1),
      );
    }
    return null;
  }

  return createMiddleware(requestHandler: _handleRequest);
}
