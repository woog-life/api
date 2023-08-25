import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/exception/time.dart';
import 'package:woog_api/src/application/exception/unsupported.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/use_case/update_temperature.dart';
import 'package:woog_api/src/application/use_case/update_tidal_extrema.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';
import 'package:woog_api/src/infrastructure/api/middleware/auth.dart';
import 'package:woog_api/src/infrastructure/api/middleware/json.dart';
import 'package:woog_api/src/infrastructure/api/middleware/trailing_slash.dart';

part 'private.g.dart';

@injectable
class PrivateApi {
  final AuthMiddleware _authMiddleware;
  final UpdateTemperature _updateTemperature;
  final UpdateTidalExtrema _updateTidalExtrema;

  Router get _router => _$PrivateApiRouter(this);

  late final Handler _handler;

  PrivateApi(
    this._authMiddleware,
    this._updateTemperature,
    this._updateTidalExtrema,
  ) {
    _handler = const Pipeline()
        .addMiddleware(trailingSlashRedirect())
        .addMiddleware(jsonHeaderMiddleware)
        .addMiddleware(_authMiddleware)
        .addHandler(_router);
  }

  FutureOr<Response> call(Request request) => _handler(request);

  @Route.put('/lake/<lakeId>/temperature')
  Future<Response> _putTemperature(Request request, String lakeId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return Response(HttpStatus.badRequest);
    }

    final Uuid lakeUuid;
    try {
      lakeUuid = Uuid.fromString(lakeId);
    } on FormatException {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto('Invalid UUID: $lakeId'),
        ),
      );
    }

    final update = TemperatureUpdateDto.fromJson(body);
    try {
      await _updateTemperature(lakeUuid, update.time, update.temperature);
      return Response(HttpStatus.noContent);
    } on NotFoundException catch (e) {
      return Response(
        HttpStatus.notFound,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
      );
    } on TimeException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto(e.toString()).toJson(),
        ),
      );
    } on UnsupportedFeatureException catch (e) {
      return Response(
        HttpStatus.notImplemented,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
      );
    }
  }

  @Route.put('/lake/<lakeId>/tides')
  Future<Response> _putTidalExtrema(Request request, String lakeId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return Response(HttpStatus.badRequest);
    }

    final Uuid lakeUuid;
    try {
      lakeUuid = Uuid.fromString(lakeId);
    } on FormatException {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto('Invalid UUID: $lakeId'),
        ),
      );
    }

    final update = TidalExtremaDto.fromJson(body);
    try {
      await _updateTidalExtrema(
        lakeId: lakeUuid,
        data: update.extrema
            .map((e) => TidalExtremumData(
                  isHighTide: e.isHighTide,
                  time: e.time,
                  height: e.height,
                ))
            .toList(growable: false),
      );
      return Response(HttpStatus.noContent);
    } on NotFoundException catch (e) {
      return Response(
        HttpStatus.notFound,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
      );
    } on TimeException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto(e.toString()).toJson(),
        ),
      );
    } on UnsupportedFeatureException catch (e) {
      return Response(
        HttpStatus.notImplemented,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
      );
    }
  }
}
