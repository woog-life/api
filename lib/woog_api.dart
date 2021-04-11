import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/lake_repository.dart';
import 'package:woog_api/src/dto.dart' as dto;
import 'package:woog_api/src/middleware/auth.dart';
import 'package:woog_api/src/middleware/cors.dart';
import 'package:woog_api/src/middleware/json.dart';
import 'package:woog_api/src/middleware/logging.dart';

class WoogApi {
  final LakeRepository _repo;
  late final Handler handler;

  WoogApi() : _repo = LakeRepository.memoryRepo() {
    final privateRouter = Router();
    privateRouter.put('/lake/<lakeId>/temperature', _updateTemperature);
    final privateHandler = const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(privateRouter);

    final publicRouter = Router(notFoundHandler: privateHandler);
    publicRouter.get('/', _getHealth);
    publicRouter.get('/health', _getHealth);
    publicRouter.get('/lake', _getLakes);
    publicRouter.get('/lake/<lakeId>', _getLake);

    handler = const Pipeline()
        .addMiddleware(jsonHeaderMiddleware)
        .addMiddleware(corsMiddleware())
        .addMiddleware(logMiddleware())
        .addHandler(publicRouter);
  }

  Future<void> launch() async {
    await io.serve(handler, InternetAddress.anyIPv4, 8080);
  }

  Response _getHealth(Request request) {
    return Response(HttpStatus.ok);
  }

  Future<Response> _getLakes(Request request) async {
    final lakes = await _repo.getLakes();

    return Response.ok(
      jsonEncode(
        dto.LakeInfoList.of(lakes).toJson(),
      ),
    );
  }

  Future<Response> _getLake(Request request, String lakeId) async {
    final lake = await _repo.getLake(lakeId);

    final precisionArgument = request.url.queryParameters['precision'];
    final int? precision;
    if (precisionArgument == null) {
      precision = null;
    } else {
      try {
        precision = min(5, max(1, int.parse(precisionArgument)));
      } on FormatException {
        return Response(HttpStatus.badRequest);
      }
    }

    if (lake == null) {
      return Response(HttpStatus.notFound);
    } else {
      return Response.ok(
        jsonEncode(dto.LakeState.fromLake(
          lake,
          precision: precision,
        ).toJson()),
      );
    }
  }

  Future<Response> _updateTemperature(Request request, String lakeId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return Response(HttpStatus.badRequest);
    }

    final update = dto.TemperatureUpdate.fromJson(body);
    try {
      _repo.updateData(lakeId, update.toData());
      return Response(HttpStatus.noContent);
    } on NotFoundException {
      return Response(HttpStatus.notFound);
    }
  }
}
