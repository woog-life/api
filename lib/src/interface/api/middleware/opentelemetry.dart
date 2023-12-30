import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:opentelemetry/api.dart';
import 'package:shelf/shelf.dart';

@immutable
@injectable
class OpenTelemetryMiddleware {
  final Tracer _tracer;

  OpenTelemetryMiddleware(TracerProvider tracerProvider)
      : _tracer = tracerProvider.getTracer('woog-opentelemetry-shelf');

  Handler call(Handler innerHandler) {
    FutureOr<Response> filteredDelegate(Request request) async {
      if (request.url.path.startsWith('health')) {
        return await innerHandler(request);
      } else {
        return await trace(
          '${request.method} /${request.url.path}',
          () async {
            final span = Context.current.span;
            span.setAttributes([
              Attribute.fromString(
                'url.full',
                request.url.toString(),
              ),
              Attribute.fromString(
                'url.path',
                '/${request.url.path}',
              ),
              Attribute.fromString(
                'url.query',
                request.url.query,
              ),
              Attribute.fromString(
                'url.scheme',
                request.url.scheme,
              ),
              Attribute.fromString(
                'network.protocol.name',
                'http',
              ),
              Attribute.fromString(
                'network.protocol.version',
                request.protocolVersion,
              ),
              Attribute.fromString(
                SemanticAttributes.httpMethod,
                request.method,
              ),
            ]);

            try {
              final response = await innerHandler(request);

              span.setAttribute(
                Attribute.fromInt(
                  SemanticAttributes.httpStatusCode,
                  response.statusCode,
                ),
              );

              if (response.statusCode >= 500) {
                span.setAttribute(Attribute.fromString(
                  'error.type',
                  '${response.statusCode}',
                ));
                span.setStatus(StatusCode.error);
              }
              return response;
            } catch (e) {
              span.setAttributes([
                Attribute.fromString(
                  'error.type',
                  e.runtimeType.toString(),
                ),
                Attribute.fromInt(SemanticAttributes.httpStatusCode, 500),
              ]);

              rethrow;
            }
          },
          tracer: _tracer,
        );
      }
    }

    return filteredDelegate;
  }
}
