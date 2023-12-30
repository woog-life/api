import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart' as otel_sdk;
import 'package:woog_api/src/config.dart';

@module
abstract class OpenTelemetryModule {
  @preResolve
  Future<TracerProvider> createTracerProvider(
    Config config,
    Logger logger,
  ) async {
    final processors = <otel_sdk.SpanProcessor>[];

    if (config.openTelemetryConsole) {
      processors.add(otel_sdk.SimpleSpanProcessor(otel_sdk.ConsoleExporter()));
    }

    if (config.openTelemetryEndpoint.isEmpty) {
      logger.i('OpenTelemetry collector exporter is disabled');
    } else {
      final headers = <String, String>{};
      final header = config.openTelemetryHeader;
      if (header.isNotEmpty) {
        final [key, value] = header.split('=');
        headers[key] = value;
      }
      final exporter = otel_sdk.CollectorExporter(
        Uri.parse('${config.openTelemetryEndpoint}/v1/traces'),
        headers: headers,
      );
      processors.add(otel_sdk.BatchSpanProcessor(exporter));
    }

    final provider = otel_sdk.TracerProviderBase(
      resource: otel_sdk.Resource([
        Attribute.fromString(ResourceAttributes.serviceName, 'woog-life'),
        Attribute.fromString(ResourceAttributes.serviceVersion, config.version),
      ]),
      processors: processors,
    );

    registerGlobalTracerProvider(provider);

    return provider;
  }
}
