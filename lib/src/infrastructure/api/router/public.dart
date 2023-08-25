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
import 'package:woog_api/src/application/use_case/get_extrema.dart';
import 'package:woog_api/src/application/use_case/get_lake.dart';
import 'package:woog_api/src/application/use_case/get_lakes.dart';
import 'package:woog_api/src/application/use_case/get_temperature.dart';
import 'package:woog_api/src/application/use_case/get_tidal_extrema.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';
import 'package:woog_api/src/infrastructure/api/middleware/json.dart';
import 'package:woog_api/src/infrastructure/api/middleware/trailing_slash.dart';

part 'public.g.dart';

@injectable
class PublicApi {
  final GetLakes _getLakes;
  final GetLake _getLake;
  final GetTemperature _getTemperature;
  final GetExtrema _getExtrema;
  final GetTidalExtrema _getTidalExtrema;

  Router get _router => _$PublicApiRouter(this);

  late final Handler _handler;

  PublicApi(
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
      );
    }

    final lake = await _getLake(lakeUuid);

    if (lake == null) {
      return Response(HttpStatus.notFound);
    } else {
      return Response.ok(
        jsonEncode(LakeInfoDto.fromLake(lake).toJson()),
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
      );
    }

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

    final data = await _getTemperature(lakeUuid, time: time);

    if (data == null) {
      return Response.notFound(const ErrorMessageDto('No lake data found'));
    }

    return Response.ok(
      jsonEncode(LakeDataDto.fromData(
        data,
        precision: precision,
        formatRegion: Region.usa,
      )),
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
      );
    }

    final DateTime? time;
    try {
      time = _getTime(request);
    } on FormatException {
      return Response(HttpStatus.badRequest);
    }

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(HttpStatus.badRequest);
    }

    final Region formatRegion;
    try {
      formatRegion = _getFormatRegion(request);
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: jsonEncode(
          ErrorMessageDto(e.message),
        ),
      );
    }

    final LakeData? temperature;
    try {
      temperature = await _getTemperature(lakeUuid, time: time);
    } on TimeException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto(e.toString()).toJson(),
        ),
      );
    }

    if (temperature == null) {
      return Response.notFound(
        jsonEncode(
          ErrorMessageDto('No temperature for lake $lakeUuid'),
        ),
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
      );
    }

    final extrema = await _getExtrema(lakeUuid);

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(HttpStatus.badRequest);
    }

    if (extrema == null) {
      return Response.notFound(
        jsonEncode(
          ErrorMessageDto('No temperatures for lake $lakeUuid'),
        ),
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
      );
    }

    final DateTime? time;
    try {
      time = _getTime(request);
    } on FormatException {
      return Response(HttpStatus.badRequest);
    }

    final upcomingLimit = parseParam(request, 'upcomingLimit', int.parse);

    if (upcomingLimit != null && (upcomingLimit < 1 || upcomingLimit > 20)) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto('Invalid upcomingLimit: $upcomingLimit'),
        ),
      );
    }

    final List<TidalExtremumData> data;
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

    return Response.ok(
      jsonEncode(
        TidalExtremaDto(
          extrema: data
              .map((e) => TidalExtremumDataDto(
                  isHighTide: e.isHighTide, time: e.time, height: e.height))
              .toList(growable: false),
        ),
      ),
    );
  }
}
