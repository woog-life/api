import 'dart:io';

import 'package:injectable/injectable.dart';

@singleton
@injectable
class Config {
  final String apiKey;
  final String sentryDsn;
  final String databaseName;
  final String databaseHost;
  final String databaseUser;
  final String databasePassword;

  factory Config() {
    final environment = Platform.environment;
    return Config._(
      apiKey: _Variable(
        name: 'API_KEY',
        defaultValue: 'default-api-key',
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
    );
  }

  Config._({
    required this.apiKey,
    required this.sentryDsn,
    required this.databaseHost,
    required this.databaseName,
    required this.databaseUser,
    required this.databasePassword,
  });
}

class _Variable {
  final String name;
  final String defaultValue;

  _Variable({
    required this.name,
    required this.defaultValue,
  });

  String resolve(Map<String, String> environment) {
    final value = environment[name];
    if (value == null) {
      stderr.writeln('$name environment variable not set');
      return defaultValue;
    } else if (value.isEmpty) {
      throw StateError('Empty $name set');
    } else {
      return value;
    }
  }
}
