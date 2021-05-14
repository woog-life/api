import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/lake_repository.dart';
import 'package:woog_api/src/dto.dart' as dto;
import 'package:woog_api/src/middleware/auth.dart';

part 'private.g.dart';

class PrivateApi {
  final LakeRepository _repo;

  Router get _router => _$PrivateApiRouter(this);
  Handler get handler =>
      const Pipeline().addMiddleware(authMiddleware()).addHandler(_router);

  PrivateApi(this._repo);

  @Route.put('/lake/<lakeId>/temperature')
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
