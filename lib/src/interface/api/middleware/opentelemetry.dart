import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:opentelemetry/api.dart';
import 'package:shelf/shelf.dart';

@immutable
@injectable
class OpenTelemetryMiddleware {
  final Logger _logger;
  final Tracer _tracer;

  OpenTelemetryMiddleware(this._logger, TracerProvider tracerProvider)
      : _tracer = tracerProvider.getTracer('woog-opentelemetry-shelf');

  Handler call(Handler innerHandler) {
    FutureOr<Response> filteredDelegate(Request request) async {
      if (request.url.path.startsWith('health')) {
        return await innerHandler(request);
      } else {
        return await trace(
          '${request.method} ${request.requestedUri.path}',
          () async {
            final span = Context.current.span;
            span.setAttributes([
              Attribute.fromString(
                'url.full',
                request.requestedUri.toString(),
              ),
              Attribute.fromString(
                'url.path',
                request.requestedUri.path,
              ),
              Attribute.fromString(
                'url.query',
                request.requestedUri.query,
              ),
              Attribute.fromString(
                'url.scheme',
                request.requestedUri.scheme,
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

              final params = response.context['shelf_router/params']
                  as Map<String, String>?;

              if (params != null) {
                var sanitizedPath = request.requestedUri.path;
                for (final entry in params.entries) {
                  sanitizedPath = sanitizedPath.replaceAll(
                    entry.value,
                    '<${entry.key}>',
                  );
                }
                span.setName('${request.method} $sanitizedPath');
              }

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
