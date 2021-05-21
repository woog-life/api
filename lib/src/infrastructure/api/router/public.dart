import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/use_case/get_interpolated_data.dart';
import 'package:woog_api/src/application/use_case/get_lake.dart';
import 'package:woog_api/src/application/use_case/get_lakes.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';

part 'public.g.dart';

@injectable
class PublicApi {
  final GetLakes _getLakes;
  final GetLake _getLake;
  final GetInterpolatedData _getInterpolatedData;

  Router get router => _$PublicApiRouter(this);

  PublicApi(
    this._getLakes,
    this._getLake,
    this._getInterpolatedData,
  );

  @Route.get('/')
  @Route.get('/health')
  Response getHealth(Request request) {
    return Response(HttpStatus.ok);
  }

  @Route.get('/lake')
  Future<Response> getLakes(Request request) async {
    final lakes = await _getLakes();

    return Response.ok(
      jsonEncode(
        LakeInfoListDto.of(lakes).toJson(),
      ),
    );
  }

  int? _getPrecision(Request request) {
    final precisionArgument = request.url.queryParameters['precision'];
    if (precisionArgument == null) {
      return null;
    } else {
      return min(5, max(1, int.parse(precisionArgument)));
    }
  }

  @Route.get('/lake/<lakeId>')
  Future<Response> getLake(Request request, String lakeId) async {
    final lake = await _getLake(lakeId);

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(HttpStatus.badRequest);
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

  @Route.get('/lake/<lakeId>/history/<timestamp>')
  Future<Response> getInterpolatedData(
    Request request,
    String lakeId,
    String timestamp,
  ) async {
    final time = DateTime.tryParse(timestamp);
    if (time == null) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(ErrorMessageDto('invalid timestamp: $timestamp')),
      );
    }

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(HttpStatus.badRequest);
    }

    final data = await _getInterpolatedData(lakeId, time);

    if (data == null) {
      return Response.notFound(const ErrorMessageDto('No lake data found'));
    }

    return Response.ok(
      jsonEncode(LakeDataDto.fromData(
        data,
        precision: precision,
      )),
    );
  }
}
