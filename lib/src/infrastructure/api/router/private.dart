import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:woog_api/src/application/use_case/update_temperature.dart';
import 'package:woog_api/src/domain/error/lake_not_found.dart';
import 'package:woog_api/src/domain/error/time.dart';
import 'package:woog_api/src/infrastructure/api/dto.dart';
import 'package:woog_api/src/infrastructure/api/middleware/auth.dart';

part 'private.g.dart';

@injectable
class PrivateApi {
  final AuthMiddleware _authMiddleware;
  final UpdateTemperature _updateTemperature;

  Router get _router => _$PrivateApiRouter(this);

  Handler get handler =>
      const Pipeline().addMiddleware(_authMiddleware).addHandler(_router);

  PrivateApi(
    this._authMiddleware,
    this._updateTemperature,
  );

  @Route.put('/lake/<lakeId>/temperature')
  Future<Response> _putTemperature(Request request, String lakeId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return Response(HttpStatus.badRequest);
    }

    final update = TemperatureUpdateDto.fromJson(body);
    try {
      await _updateTemperature(lakeId, update.time, update.temperature);
      return Response(HttpStatus.noContent);
    } on LakeNotFoundError catch (e) {
      return Response(
        HttpStatus.notFound,
        body: jsonEncode(
          ErrorMessageDto(e.toString()),
        ),
      );
    } on TimeError catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: jsonEncode(
          ErrorMessageDto(e.toString()).toJson(),
        ),
      );
    }
  }
}
