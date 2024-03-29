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
import 'package:woog_api/src/interface/api/dto.dart';
import 'package:woog_api/src/interface/api/middleware/auth.dart';
import 'package:woog_api/src/interface/api/middleware/json.dart';
import 'package:woog_api/src/interface/api/middleware/trailing_slash.dart';

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
      return Response(
        HttpStatus.badRequest,
        context: request.context,
      );
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
        context: request.context,
      );
    }

    final update = TemperatureUpdateDto.fromJson(body);
    try {
      await _updateTemperature(lakeUuid, update.time, update.temperature);
      return Response(
        HttpStatus.noContent,
        context: request.context,
      );
    } on NotFoundException catch (e) {
      return Response(
        HttpStatus.notFound,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
        context: request.context,
      );
    } on TimeException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto(e.toString()).toJson(),
        ),
        context: request.context,
      );
    } on UnsupportedFeatureException catch (e) {
      return Response(
        HttpStatus.notImplemented,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
        context: request.context,
      );
    }
  }

  @Route.put('/lake/<lakeId>/tides')
  Future<Response> _putTidalExtrema(Request request, String lakeId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return Response(
        HttpStatus.badRequest,
        context: request.context,
      );
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
        context: request.context,
      );
    }

    final update = TidalExtremaInputDto.fromJson(body);
    final extrema = <TidalExtremumData>[];
    for (final extremum in update.extrema) {
      // We try to parse the height as double just to validate the format, but
      // keep the string around so we don't get weird float formatting.
      if (double.tryParse(extremum.height) == null) {
        return Response(
          HttpStatus.badRequest,
          body: jsonEncode(
            ErrorMessageDto(
              'Invalid height at time ${extremum.time}: ${extremum.height}',
            ),
          ),
          context: request.context,
        );
      }

      extrema.add(TidalExtremumData(
        isHighTide: extremum.isHighTide,
        time: extremum.time,
        height: extremum.height,
      ));
    }

    if (extrema.length < 2) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto('Must PUT at least two extrema'),
        ),
        context: request.context,
      );
    }

    try {
      await _updateTidalExtrema(
        lakeId: lakeUuid,
        data: extrema,
      );
      return Response(
        HttpStatus.noContent,
        context: request.context,
      );
    } on NotFoundException catch (e) {
      return Response(
        HttpStatus.notFound,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
        context: request.context,
      );
    } on TimeException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto(e.toString()).toJson(),
        ),
        context: request.context,
      );
    } on UnsupportedFeatureException catch (e) {
      return Response(
        HttpStatus.notImplemented,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
        context: request.context,
      );
    }
  }
}
