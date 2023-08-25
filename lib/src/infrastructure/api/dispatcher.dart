import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:woog_api/src/infrastructure/api/http_constants.dart';
import 'package:woog_api/src/infrastructure/api/router/private.dart';
import 'package:woog_api/src/infrastructure/api/router/public.dart';
import 'package:woog_api/src/infrastructure/api/router/static.dart';

@injectable
@immutable
final class Dispatcher {
  final PrivateApi _privateApi;
  final PublicApi _publicApi;
  final StaticServer _staticServer;

  Dispatcher(
    this._privateApi,
    this._publicApi,
    this._staticServer,
  );

  bool _hasBasePath(Request request, String basePath) {
    final segments = request.url.pathSegments;
    if (segments.isEmpty) {
      return false;
    }

    return segments.first == basePath;
  }

  FutureOr<Response> call(Request request) {
    final method = HttpMethod.fromValue(request.method);
    if (method == null) {
      throw ArgumentError.value(method, 'method', 'Invalid HTTP method');
    } else if (method == HttpMethod.get && _hasBasePath(request, 'docs')) {
      return _staticServer(request.change(path: 'docs'));
    } else if (method == HttpMethod.get && request.url.hasEmptyPath) {
      return Response.movedPermanently('/docs');
    } else if (method.isSafe) {
      return _publicApi(request);
    } else {
      return _privateApi(request);
    }
  }
}
