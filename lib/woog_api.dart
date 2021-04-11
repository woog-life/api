import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/lake_repository.dart';
import 'package:woog_api/model/lake_data.dart';
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
      jsonEncode([
        for (final lake in lakes)
          {
            'id': lake.id,
            'name': lake.name,
          },
      ]),
    );
  }

  Future<Response> _getLake(Request request, String lakeId) async {
    final lake = await _repo.getLake(lakeId);

    if (lake == null) {
      return Response(HttpStatus.notFound);
    } else {
      final data = lake.data;
      return Response.ok(
        jsonEncode({
          'id': lake.id,
          'name': lake.name,
          'data': data == null
              ? null
              : {
                  'time': data.time.toIso8601String(),
                  'temperature': data.temperature,
                }
        }),
      );
    }
  }

  Future<Response> _updateTemperature(Request request, String lakeId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map) {
      return Response(HttpStatus.badRequest);
    }
    final timeString = body['time'];
    final temperature = body['temperature'];
    if (timeString is String && temperature is double) {
      final data = LakeData(
        time: DateTime.parse(timeString),
        temperature: temperature.round(),
      );

      try {
        _repo.updateData(lakeId, data);
        return Response(HttpStatus.noContent);
      } on NotFoundException {
        return Response(HttpStatus.notFound);
      }
    } else {
      return Response(HttpStatus.badRequest);
    }
  }
}
