import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/exception/not_found.dart';
import 'package:woog_api/src/application/exception/time.dart';
import 'package:woog_api/src/application/exception/unsupported.dart';
import 'package:woog_api/src/application/model/lake_data.dart';
import 'package:woog_api/src/application/model/region.dart';
import 'package:woog_api/src/application/model/tidal_extremum_data.dart';
import 'package:woog_api/src/application/repository/unit_of_work.dart';
import 'package:woog_api/src/application/use_case/get_extrema.dart';
import 'package:woog_api/src/application/use_case/get_lake.dart';
import 'package:woog_api/src/application/use_case/get_lakes.dart';
import 'package:woog_api/src/application/use_case/get_temperature.dart';
import 'package:woog_api/src/application/use_case/get_tidal_extrema.dart';
import 'package:woog_api/src/interface/api/dto.dart';
import 'package:woog_api/src/interface/api/middleware/json.dart';
import 'package:woog_api/src/interface/api/middleware/trailing_slash.dart';

part 'public.g.dart';

@injectable
class PublicApi {
  final UnitOfWorkProvider _uowProvider;
  final GetLakes _getLakes;
  final GetLake _getLake;
  final GetTemperature _getTemperature;
  final GetExtrema _getExtrema;
  final GetTidalExtrema _getTidalExtrema;

  Router get _router => _$PublicApiRouter(this);

  late final Handler _handler;

  PublicApi(
    this._uowProvider,
    this._getLakes,
    this._getLake,
    this._getTemperature,
    this._getExtrema,
    this._getTidalExtrema,
  ) {
    _handler = const Pipeline()
        .addMiddleware(trailingSlashRedirect())
        .addMiddleware(jsonHeaderMiddleware)
        .addHandler(_router);
  }

  FutureOr<Response> call(Request request) => _handler(request);

  @Route.get('/')
  @Route.get('/health/live')
  Response getLiveness(Request request) {
    return Response(HttpStatus.ok);
  }

  @Route.get('/health/ready')
  Response getReadiness(Request request) {
    if (_uowProvider.isReady) {
      return Response(HttpStatus.ok);
    } else {
      return Response(HttpStatus.serviceUnavailable);
    }
  }

  @Route.get('/lake')
  Future<Response> getLakes(Request request) async {
    final lakes = await _getLakes();

    return Response.ok(
      jsonEncode(
        LakeInfoListDto.of(lakes).toJson(),
      ),
      context: request.context,
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

  Region _getFormatRegion(Request request) {
    final arg = request.url.queryParameters['formatRegion'];
    if (arg == null) {
      return Region.usa;
    } else {
      final region = Region.parseIdentifier(arg);
      if (region == null) {
        throw ArgumentError.value(
          arg,
          'formatRegion',
          'Invalid region identifier',
        );
      }
      return region;
    }
  }

  @Route.get('/lake/<lakeId>')
  Future<Response> getLake(Request request, String lakeId) async {
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

    final lake = await _getLake(lakeUuid);

    if (lake == null) {
      return Response(
        HttpStatus.notFound,
        context: request.context,
      );
    } else {
      return Response.ok(
        jsonEncode(LakeInfoDto.fromLake(lake).toJson()),
        context: request.context,
      );
    }
  }

  @Route.get('/lake/<lakeId>/history/<timestamp>')
  Future<Response> getInterpolatedData(
    Request request,
    String lakeId,
    String timestamp,
  ) async {
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

    final time = DateTime.tryParse(timestamp);
    if (time == null) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(ErrorMessageDto('invalid timestamp: $timestamp')),
        context: request.context,
      );
    }

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(
        HttpStatus.badRequest,
        context: request.context,
      );
    }

    final data = await _getTemperature(lakeUuid, time: time);

    if (data == null) {
      return Response.notFound(
        const ErrorMessageDto('No lake data found'),
        context: request.context,
      );
    }

    return Response.ok(
      jsonEncode(LakeDataDto.fromData(
        data,
        precision: precision,
        formatRegion: Region.usa,
      )),
      context: request.context,
    );
  }

  DateTime? _getTime(Request request) {
    final atArgument = request.url.queryParameters['at'];
    if (atArgument == null) {
      return null;
    } else {
      return DateTime.parse(atArgument);
    }
  }

  @Route.get('/lake/<lakeId>/temperature')
  Future<Response> getTemperature(Request request, String lakeId) async {
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

    final DateTime? time;
    try {
      time = _getTime(request);
    } on FormatException {
      return Response(
        HttpStatus.badRequest,
        context: request.context,
      );
    }

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(
        HttpStatus.badRequest,
        context: request.context,
      );
    }

    final Region formatRegion;
    try {
      formatRegion = _getFormatRegion(request);
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: jsonEncode(ErrorMessageDto(e.message)),
        context: request.context,
      );
    }

    final LocalizedLakeData? temperature;
    try {
      temperature = await _getTemperature(lakeUuid, time: time);
    } on TimeException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto(e.toString()).toJson(),
        ),
        context: request.context,
      );
    }

    if (temperature == null) {
      return Response.notFound(
        jsonEncode(
          ErrorMessageDto('No temperature for lake $lakeUuid'),
        ),
        context: request.context,
      );
    }

    return Response.ok(
      jsonEncode(
        LakeDataDto.fromData(
          temperature,
          precision: precision,
          formatRegion: formatRegion,
        ),
      ),
      context: request.context,
    );
  }

  @Route.get('/lake/<lakeId>/temperature/extrema')
  Future<Response> getExtrema(Request request, String lakeId) async {
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

    final extrema = await _getExtrema(lakeUuid);

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(
        HttpStatus.badRequest,
        context: request.context,
      );
    }

    if (extrema == null) {
      return Response.notFound(
        jsonEncode(
          ErrorMessageDto('No temperatures for lake $lakeUuid'),
        ),
        context: request.context,
      );
    }

    final Region formatRegion;
    try {
      formatRegion = _getFormatRegion(request);
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: jsonEncode(
          ErrorMessageDto(e.message),
        ),
        context: request.context,
      );
    }

    return Response.ok(
      jsonEncode(
        LakeDataExtremaDto.fromData(
          extrema.min,
          extrema.max,
          precision: precision,
          formatRegion: formatRegion,
        ),
      ),
      context: request.context,
    );
  }

  T? parseParam<T>(Request request, String name, T Function(String) parse) {
    final arg = request.url.queryParameters[name];
    if (arg == null) {
      return null;
    }

    return parse(arg);
  }

  @Route.get('/lake/<lakeId>/tides')
  Future<Response> getTidalExtrema(Request request, String lakeId) async {
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

    final DateTime? time;
    try {
      time = _getTime(request);
    } on FormatException {
      return Response(
        HttpStatus.badRequest,
        context: request.context,
      );
    }

    final upcomingLimit = parseParam(request, 'upcomingLimit', int.parse);

    if (upcomingLimit != null && (upcomingLimit < 1 || upcomingLimit > 20)) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto('Invalid upcomingLimit: $upcomingLimit'),
        ),
        context: request.context,
      );
    }

    final List<LocalizedTidalExtremumData> data;
    try {
      data = await _getTidalExtrema(
        lakeId: lakeUuid,
        time: time,
        upcomingLimit: upcomingLimit,
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

    return Response.ok(
      jsonEncode(
        TidalExtremaDto(
          extrema:
              data.map(TidalExtremumDataDto.fromData).toList(growable: false),
        ),
      ),
      context: request.context,
    );
  }
}
