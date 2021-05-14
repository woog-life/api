import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:woog_api/src/infrastructure/api/http_constants.dart';
import 'package:woog_api/src/infrastructure/api/router/private.dart';
import 'package:woog_api/src/infrastructure/api/router/public.dart';

@injectable
class Dispatcher {
  final PrivateApi _privateApi;
  final PublicApi _publicApi;

  Dispatcher(
    this._privateApi,
    this._publicApi,
  );

  FutureOr<Response> call(Request request) {
    final method = matchHttpMethod(request.method);
    if (method == null) {
      throw ArgumentError.value(method, 'method', 'Invalid HTTP method');
    } else if (method.isSafe) {
      return _publicApi.router(request);
    } else {
      return _privateApi.handler(request);
    }
  }
}
