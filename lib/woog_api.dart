import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:woog_api/lake_repository.dart';
import 'package:woog_api/src/http_constants.dart';
import 'package:woog_api/src/middleware/cors.dart';
import 'package:woog_api/src/middleware/json.dart';
import 'package:woog_api/src/middleware/logging.dart';
import 'package:woog_api/src/router/private.dart';
import 'package:woog_api/src/router/public.dart';

class WoogApi {
  final LakeRepository _repo;
  late final Handler handler;

  WoogApi() : _repo = LakeRepository.memoryRepo() {
    final dispatcher = _Dispatcher(_repo);

    handler = const Pipeline()
        .addMiddleware(jsonHeaderMiddleware)
        .addMiddleware(corsMiddleware())
        .addMiddleware(logMiddleware())
        .addHandler(dispatcher);
  }

  Future<void> launch() async {
    await io.serve(handler, InternetAddress.anyIPv4, 8080);
  }
}

class _Dispatcher {
  final PrivateApi _privateApi;
  final PublicApi _publicApi;

  _Dispatcher(LakeRepository repo)
      : _privateApi = PrivateApi(repo),
        _publicApi = PublicApi(repo);

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
