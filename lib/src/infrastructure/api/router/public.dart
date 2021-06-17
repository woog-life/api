import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/use_case/get_events.dart';
import 'package:woog_api/src/application/use_case/get_interpolated_data.dart';
import 'package:woog_api/src/application/use_case/get_lake.dart';
import 'package:woog_api/src/application/use_case/get_lake_data.dart';
import 'package:woog_api/src/application/use_case/get_lakes.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';
import 'package:woog_api/src/infrastructure/api/middleware/json.dart';
import 'package:woog_api/src/infrastructure/api/middleware/trailing_slash.dart';

part 'public.g.dart';

@injectable
class PublicApi {
  final GetLakes _getLakes;
  final GetLake _getLake;
  final GetTemperature _getTemperature;
  final GetInterpolatedData _getInterpolatedData;
  final GetEvents _getEvents;

  Router get _router => _$PublicApiRouter(this);

  late final Handler _handler;

  PublicApi(
    this._getLakes,
    this._getLake,
    this._getTemperature,
    this._getInterpolatedData,
    this._getEvents,
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
    final lakeData = await _getTemperature(lakeUuid);

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
          lakeData,
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

    final data = await _getInterpolatedData(lakeUuid, time);

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

    final temperature = await _getTemperature(lakeUuid);

    final int? precision;
    try {
      precision = _getPrecision(request);
    } on FormatException {
      return Response(HttpStatus.badRequest);
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
        ),
      ),
    );
  }

  @Route.get('/lake/<lakeId>/booking')
  Future<Response> _getBooking(Request request, String lakeId) async {
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

    final events = await _getEvents(lakeUuid);

    return Response.ok(
      jsonEncode(EventsDto(
        [
          for (final event in events)
            EventDto(
              variation: event.variation,
              bookingLink: event.bookingLink,
              beginTime: event.beginTime,
              endTime: event.endTime,
              saleStartTime: event.saleStartTime,
            )
        ],
      )),
    );
  }
}
