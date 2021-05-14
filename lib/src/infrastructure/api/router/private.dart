import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/repository/exception.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';
import 'package:woog_api/src/infrastructure/api/middleware/auth.dart';

part 'private.g.dart';

@injectable
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

    final update = TemperatureUpdateDto.fromJson(body);
    try {
      _repo.updateData(lakeId, update.toData());
      return Response(HttpStatus.noContent);
    } on NotFoundException {
      return Response(HttpStatus.notFound);
    }
  }
}
