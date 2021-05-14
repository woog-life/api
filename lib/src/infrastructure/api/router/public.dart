import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/repository/lake.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';

part 'public.g.dart';

@injectable
class PublicApi {
  final LakeRepository _repo;

  Router get router => _$PublicApiRouter(this);

  PublicApi(this._repo);

  @Route.get('/')
  @Route.get('/health')
  Response _getHealth(Request request) {
    return Response(HttpStatus.ok);
  }

  @Route.get('/lake')
  Future<Response> _getLakes(Request request) async {
    final lakes = await _repo.getLakes();

    return Response.ok(
      jsonEncode(
        LakeInfoListDto.of(lakes).toJson(),
      ),
    );
  }

  @Route.get('/lake/<lakeId>')
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
        jsonEncode(LakeStateDto.fromLake(
          lake,
          precision: precision,
        ).toJson()),
      );
    }
  }
}
