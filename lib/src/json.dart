import 'dart:io';

import 'package:shelf/shelf.dart';

Handler jsonHeaderMiddleware(Handler handler) {
  Future<Response> _addJsonHeader(Request request) async {
    final response = await handler(request);
    if (response.contentLength == 0) {
      return response;
    } else {
      return response.change(
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
        },
      );
    }
  }

  return _addJsonHeader;
}
