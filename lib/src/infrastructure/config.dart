import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:woog_api/src/version.dart';

@singleton
@injectable
@immutable
final class Config {
  final String version;
  final String build;

  final String apiKey;

  final bool openTelemetryConsole;
  final String openTelemetryEndpoint;
  final String openTelemetryHeader;
  final String sentryDsn;

  final String databaseName;
  final String databaseHost;
  final String databaseUser;
  final String databasePassword;
  final bool databaseUseTls;

  final String docsPath;

  factory Config() {
    final environment = Platform.environment;
    return Config._(
      version: packageVersion,
      build: _Variable(
        name: 'BUILD_SHA',
        defaultValue: 'dev',
      ).resolve(environment),
      apiKey: _Variable(
        name: 'API_KEY',
        defaultValue: 'default-api-key',
      ).resolve(environment),
      openTelemetryConsole: _Variable(
            name: 'OTEL_EXPORTER_CONSOLE',
            defaultValue: 'true',
          ).resolve(environment) ==
          'true',
      openTelemetryEndpoint: _Variable(
        name: 'OTEL_EXPORTER_OTLP_ENDPOINT',
        defaultValue: '',
      ).resolve(environment),
      openTelemetryHeader: _Variable(
        name: 'OTEL_EXPORTER_OTLP_HEADERS',
        defaultValue: '',
      ).resolve(environment),
      sentryDsn: _Variable(
        name: 'SENTRY_DSN',
        defaultValue: '',
      ).resolve(environment),
      databaseName: _Variable(
        name: 'POSTGRES_DB',
        defaultValue: 'postgres',
      ).resolve(environment),
      databaseHost: _Variable(
        name: 'POSTGRES_HOSTNAME',
        defaultValue: 'localhost',
      ).resolve(environment),
      databaseUser: _Variable(
        name: 'POSTGRES_USER',
        defaultValue: 'postgres',
      ).resolve(environment),
      databasePassword: _Variable(
        name: 'POSTGRES_PASSWORD',
        defaultValue: 'pw',
      ).resolve(environment),
      databaseUseTls: _Variable(
            name: 'POSTGRES_USE_TLS',
            defaultValue: 'false',
          ).resolve(environment) ==
          'true',
      docsPath: _Variable(
        name: 'DOCS_PATH',
        defaultValue: '',
      ).resolve(environment),
    );
  }

  Config._({
    required this.version,
    required this.build,
    required this.apiKey,
    required this.openTelemetryConsole,
    required this.openTelemetryEndpoint,
    required this.openTelemetryHeader,
    required this.sentryDsn,
    required this.databaseHost,
    required this.databaseName,
    required this.databaseUser,
    required this.databasePassword,
    required this.databaseUseTls,
    required this.docsPath,
  });
}

@immutable
final class _Variable {
  final String name;
  final String defaultValue;

  _Variable({
    required this.name,
    required this.defaultValue,
  });

  String resolve(Map<String, String> environment) {
    final value = environment[name];
    if (value == null || value.isEmpty) {
      stderr.writeln('$name environment variable not set or empty');
      return defaultValue;
    } else {
      return value;
    }
  }
}
