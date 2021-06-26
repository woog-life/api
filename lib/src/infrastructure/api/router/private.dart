import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/use_case/update_events.dart';
import 'package:woog_api/src/application/use_case/update_temperature.dart';
import 'package:woog_api/src/domain/exception/lake_not_found.dart';
import 'package:woog_api/src/domain/exception/time.dart';
import 'package:woog_api/src/domain/exception/unsupported.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';
import 'package:woog_api/src/infrastructure/api/middleware/auth.dart';
import 'package:woog_api/src/infrastructure/api/middleware/json.dart';
import 'package:woog_api/src/infrastructure/api/middleware/trailing_slash.dart';

part 'private.g.dart';

@injectable
class PrivateApi {
  final Logger _logger;
  final AuthMiddleware _authMiddleware;
  final UpdateTemperature _updateTemperature;
  final UpdateEvents _updateEvents;

  Router get _router => _$PrivateApiRouter(this);

  late final Handler _handler;

  PrivateApi(
    this._logger,
    this._authMiddleware,
    this._updateTemperature,
    this._updateEvents,
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
    } on LakeNotFoundException catch (e) {
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

  @Route.put('/lake/<lakeId>/booking')
  Future<Response> _putBooking(Request request, String lakeId) async {
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

    final EventsUpdateDto update;
    final List events = body['events'] as List;
    if (events.isEmpty) {
      update = EventsUpdateDto.fromJson(body);
    } else if ((events.first as Map).containsKey('is_available')) {
      _logger.w('Received legacy booking update');
      update = LegacyEventsUpdateDto.fromJson(body);
    } else {
      update = EventsUpdateDto.fromJson(body);
    }

    try {
      await _updateEvents(
        lakeUuid,
        update.variation,
        update.events
            .map(
              (e) => UpdateEvent(
                bookingLink: e.bookingLink,
                beginTime: e.beginTime,
                endTime: e.endTime,
                saleStartTime: e.saleStartTime,
                isAvailable: e.isAvailable,
              ),
            )
            .toList(growable: false),
      );
      return Response(HttpStatus.noContent);
    } on LakeNotFoundException catch (e) {
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
